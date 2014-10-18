require './config/boot'
require './config/environment'
require 'clockwork'
require 'twitter'
require 'tweets_parser'
require 'extensions'

module Clockwork

  every(30.minutes, "[#{DateTime.now.to_s}] Fetching and saving sentences from tweets") do
    # handles = get_fetch_client.friends.map(&:screen_name).shuffle.first(15)
    # handles.each do |handle|
    #   save_tweets(get_parser.get_latest_sentences(handle))
    # end
  end

  every(1.day, "[#{DateTime.now.to_s}] Deleting tweets older than one day") do
    # Tweet.where(:created_at.lte => (Date.today-1)).destroy_all
  end

  every(30.seconds, "[#{DateTime.now.to_s}] Saving Haiku candidates") do
    # puts generate_haiku_candidate
  end

  class << self

    def generate_haiku_candidate
      tweets = Tweet.all.desc('_id').limit(3000)
      verse1 = get_verse(tweets, 5)
      verse2 = get_verse(tweets, 7)
      verse3 = get_verse(tweets, 5)

      handle1 = verse1[0].handle
      handle2 = verse2[0].handle
      handle3 = verse3[0].handle

      tweet = ""
      tweet.concat(verse1[1])
      tweet.concat("\n")
      tweet.concat(verse2[1])
      tweet.concat("\n")
      tweet.concat(verse3[1])
      tweet.concat("\n")
      tweet.concat("#haiku from @#{handle1} @#{handle2} @#{handle3}")
    end

    def get_verse(tweets, n)
      safety_fuse = 0
      loop do
        tweet = tweets.sample
        verse = try_verse(tweet.sentences.sample, n)
        return [tweet, verse] if verse.present?
        safety_fuse =+ 1
        return nil if safety_fuse > 3000
      end
    end

    def try_verse(sentence, n)
      words = sentence.split(" ")
      0.upto(words.length) do |i|
        verse = words[0..i].join(" ")
        return get_parser.sanitize_sentence(verse) if verse.count_syllables == n
      end
      nil
    end

    def save_tweets(tweets)
      tweets.each do |tweet|
        if Tweet.where(tweet_id: tweet[:tweet_id]).empty?
          Tweet.create(tweet_id: tweet[:tweet_id], handle: tweet[:handle], sentences: tweet[:sentences])
          puts "saved sentences from tweet #{tweet[:tweet_id]}"
        end
      end
    end

    def get_fetch_client
      @fetch_client ||= Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token = ENV["TWITTER_ACCESS_TOKEN"]
        config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
      end
    end

    def get_post_client
      @post_client ||= Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["BOT_TWITTER_CONSUMER_KEY"]
        config.consumer_secret = ENV["BOT_TWITTER_CONSUMER_SECRET"]
        config.access_token = ENV["BOT_TWITTER_ACCESS_TOKEN"]
        config.access_token_secret = ENV["BOT_TWITTER_ACCESS_TOKEN_SECRET"]
      end
    end

    def get_parser
      @parser ||= TweetsParser.new(get_fetch_client)
    end
  end
end
