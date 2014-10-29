require "wtf_lang"

class TweetsParser

  def initialize(twitter_client)
    @client = twitter_client
  end

  def fetch_latest_tweets(handle)
    begin
      @client.user_timeline(handle)
      .select{|tweet| !tweet.retweet? && !tweet.reply?}
      .map{ |tweet| { id: tweet.id, handle: handle, text: sanitize_tweet(tweet.text.dup) } }
    rescue Exception => ex
      puts ex
    end
  end

  # remove mentions and hashtags
  def sanitize_tweet(tweet)
    tweet.gsub!(/\B[@#]\S+\b/, '')
    tweet.gsub!(%r"((?:(?:[^ :/?#]+):)(?://(?:[^ /?#]*))(?:[^ ?#]*)(?:\?(?:[^ #]*))?(?:#(?:[^ ]*))?)", '') #urls
    tweet.downcase!
    tweet.strip
  end

  def sanitize_sentence(sentence)
    sentence.strip!
    sentence.gsub!("  ", " ")
    sentence.gsub!("-", " ")
    sentence.gsub!(" ,", ",")
    sentence.gsub!("\"", "")
    sentence.gsub!(/\,+$/, '')
    sentence.gsub!("\"", "")
    sentence.strip
  end

  def extract_sentences(tweet)
    lines = tweet.split("\n")
    sentences = []
    lines.each do |line|
      sentences << line.split(/[.?!]/).map{ |sentence| sanitize_sentence(sentence.strip) }.reject{|a| a.strip == "" }
    end
    sentences.flatten
  end

  def get_latest_sentences(handle)
    sanitized_tweets = fetch_latest_tweets(handle)
    sentences = []
    sanitized_tweets.each do |tweet|
      begin
        lang = tweet[:text].lang
      rescue
        raise "lang api error"
      end
      if tweet[:text].lang == "en"
        sentences << { tweet_id: tweet[:id], handle: tweet[:handle], sentences: extract_sentences(tweet[:text]) }
      end
    end
    sentences.flatten
  end
end
