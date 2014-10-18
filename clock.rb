require './config/boot'
require './config/environment'
require 'clockwork'
require 'twitter'
require 'tweets_parser'
require 'extensions'

module Clockwork

  every(30.minutes, "[#{DateTime.now.to_s}] Fetching and saving sentences from tweets") do
    handles = get_authenticated_client.friends.map(&:screen_name).shuffle.first(15)
    handles.each do |handle|
      save_tweets(get_parser.get_latest_sentences(handle))
    end
  end

  class << self

    def save_tweets(tweets)
      tweets.each do |tweet|
        if Tweet.where(tweet_id: tweet[:tweet_id]).empty?
          Tweet.create(tweet_id: tweet[:tweet_id], handle: tweet[:handle], sentences: tweet[:sentences])
          puts "saved sentences from tweet #{tweet[:tweet_id]}"
        end
      end
    end

    def get_authenticated_client
      @client ||= Twitter::REST::Client.new do |config|
        config.consumer_key = ENV["TWITTER_CONSUMER_KEY"]
        config.consumer_secret = ENV["TWITTER_CONSUMER_SECRET"]
        config.access_token = ENV["TWITTER_ACCESS_TOKEN"]
        config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
      end
    end

    def get_parser
      @parser ||= TweetsParser.new(get_authenticated_client)
    end
  end
end
