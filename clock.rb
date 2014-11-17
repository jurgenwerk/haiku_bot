require './config/boot'
require './config/environment'
require 'clockwork'
require 'twitter'
require 'tweets_parser'
require 'extensions'

module Clockwork

  every(4.hours, "[#{DateTime.now.to_s}] Fetching and saving sentences from tweets") do
    begin
      handles = get_fetch_client.friends.map(&:screen_name).shuffle.first(15)
      handles.each do |handle|
        save_tweets(get_parser.get_latest_sentences(handle))
      end
    rescue Exception => e
      puts "Fail while fetching tweets and saving sentences"
      puts e.message
    end
  end

  every(1.day, "[#{DateTime.now.to_s}] Deleting old tweets") do
    begin
      Tweet.where(:created_at.lte => (DateTime.current - 1.day)).destroy_all
    rescue Exception => e
      puts "Fail while deleting old tweets"
      puts e.message
    end
  end

  every(1.day, "[#{DateTime.now.to_s}] Deleting old published Haikus") do
    begin
      Haiku.where(published: true, :created_at.lte => (DateTime.current - 5.day)).destroy_all
    rescue Exception => e
      puts "Fail while deleting old published tweets"
      puts e.message
    end
  end

  every(5.minutes, "[#{DateTime.now.to_s}] Saving a new Haiku candidate") do
    begin
      tweets = Tweet.where(used: false).all.desc('_id').limit(3000).shuffle
      haiku = generate_haiku_candidate(tweets)
      if haiku.present? && haiku.length <= 140
        h = Haiku.create(text: haiku)
        puts "Saved haiku candidate \n #{h.text} \n #{h.id}"
      end
    rescue Exception => e
      puts "Fail while saving new haiku candidates"
      puts e.message
    end
  end

  every(20.minutes, "[#{DateTime.now.to_s}] Publishing Haiku candidates") do
    begin
      haiku = Haiku.where(for_publishing: true, published: false).sample
      if haiku.present?
        client = get_post_client
        client.update(haiku.text)
        haiku.published = true
        haiku.save
      end
    rescue Exception => e
      puts "Fail while publishing Haiku candidates"
      puts e.message
    end
  end

  class << self

    #todo move this stuff into separate class and extract persistence layer from it.

    def generate_haiku_candidate(tweets)
      return nil if tweets.empty?
      verse1 = get_verse(tweets, 5)
      verse2 = get_verse(tweets, 7)
      verse3 = get_verse(tweets, 5)

      handle1 = verse1[0].handle
      handle2 = verse2[0].handle
      handle3 = verse3[0].handle

      handles = [handle1, handle2, handle3].uniq.map{|handle| "@#{handle}"}.join(" ")

      mark_tweets_as_used!([verse1[0], verse2[0], verse3[0]])

      tweet = ""
      tweet.concat(verse1[1])
      tweet.concat("\n")
      tweet.concat(verse2[1])
      tweet.concat("\n")
      tweet.concat(verse3[1])
      tweet.concat("\n")
      tweet.concat("#haiku from #{handles}")
    end

    def mark_tweets_as_used!(tweets)
      tweets.each do |tweet|
        tweet.used = true
        tweet.save
      end
    end

    def get_verse(tweets, n)
      return nil if tweets.empty?
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
      if sentence
        words = sentence.split(" ")
        0.upto(words.length) do |i|
          verse = words[0..i].join(" ")
          return get_parser.sanitize_sentence(verse) if verse.count_syllables == n
        end
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
