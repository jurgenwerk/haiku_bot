class Haiku
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, type: String
  field :for_publishing, type: Boolean, default: false
  field :published, type: Boolean, default: false
end
