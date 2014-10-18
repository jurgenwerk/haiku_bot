class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :tweet_id, type: Integer
  field :handle, type: String
  field :sentences, type: Array
end
