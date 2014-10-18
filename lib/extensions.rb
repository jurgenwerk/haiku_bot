class String
  def count_syllables
    # return 1 if self.length <= 3
    # self.downcase!
    # self.sub!(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, '')
    # self.sub!(/^y/, '')
    # self.scan(/[aeiouy]{1,2}/).size
    consonants = "bcdfghjklmnpqrstvwxz"
    vowels = "aeiouy"
    processed = self.downcase
    suffix_bonus = 0
    #puts "*** 0 #{processed}"
    if processed.match(/ly$/)
      suffix_bonus = 1
      processed.gsub!(/ly$/, "")
    end
    if processed.match(/[a-z]ed$/)
      # Not counting "ed" as an extra symbol.
      # So 'blessed' is assumed to be said as 'blest'
      suffix_bonus = 0
      processed.gsub!(/ed$/, "")
    end
    processed.gsub!(/iou|eau|ai|au|ay|ea|ee|ei|oa|oi|oo|ou|ui|oy/, "@") #vowel combos
    processed.gsub!(/qu|ng|ch|rt|[#{consonants}h]/, "=") #consonant combos
    processed.gsub!(/[#{vowels}@][#{consonants}=]e$/, "@|") # remove silent e
    processed.gsub!(/[#{vowels}]/, "@") #all remaining vowels will be counted
    processed.count("@") + suffix_bonus
  end
end
