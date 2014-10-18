class String
  def count_syllables
    return 1 if self.length <= 3
    self.downcase!
    self.sub!(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, '')
    self.sub!(/^y/, '')
    self.scan(/[aeiouy]{1,2}/).size
  end
end
