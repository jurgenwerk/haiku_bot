require './config/boot'
require './config/environment'
require 'clockwork'
require 'twitter'
require 'tweets_parser'

module Clockwork

  every(10.minutes, "[#{DateTime.now.to_s}] Fetching and saving sentences from tweets") do
    tweets_parser = get_parser
    puts tweets_parser.get_latest_sentences("matixmatix")
  end

  class << self

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
