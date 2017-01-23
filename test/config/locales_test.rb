class LocalesTest < ActionController::TestCase
  test "have same keys" do
    locales = {}
    Settings.available_locales.each do |locale|
      locales[locale] = YAML.safe_load(File.read("config/locales/#{locale}.yml"))[locale]
    end
    locales.each do |locale1, locales1|
      locales.each do |locale2, locales2|
        next if locale1 == locale2
        diff = []
        compare_hash_by_keys(
          diff,
          [locale1, locales1],
          [locale2, locales2],
        )
        assert_empty(diff)
      end
    end
  end

  def compare_hash_by_keys(diff, hash1, hash2)
    no_hash1_keys_in_hash2(diff, hash1, hash2)
    no_hash1_keys_in_hash2(diff, hash2, hash1)
  end

  def no_hash1_keys_in_hash2(diff, hash1, hash2)
    hash1.second.each_key do |key|
      next unless hash2.second.class == Hash
      if hash1.second[key].class != Hash
        next if hash2.second.key?(key)
        diff.push("no '#{key}' of '#{hash1.first}' in '#{hash2.first}'")
      else
        no_hash1_keys_in_hash2(
          diff,
          [hash1.first, hash1.second[key]], [hash2.first, hash2.second[key]]
        )
      end
    end
  end
end
