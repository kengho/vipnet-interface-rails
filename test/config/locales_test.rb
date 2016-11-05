class LocalesTest < ActionController::TestCase
  test "have same keys" do
    localizations = Hash.new
    Settings.available_locales.each do |locale|
      localizations[locale] = YAML.load(File.read("config/locales/#{locale}.yml"))[locale]
    end
    localizations.each do |locale1, localizations1|
      localizations.each do |locale2, localizations2|
        next if locale1 == locale2
        diff = Array.new
        compare_hash_by_keys(diff, [locale1, localizations1], [locale2, localizations2])
        assert_empty(diff)
      end
    end
  end

  def compare_hash_by_keys(diff, hash1, hash2)
    no_hash1_keys_in_hash2(diff, hash1, hash2)
    no_hash1_keys_in_hash2(diff, hash2, hash1)
  end

  def no_hash1_keys_in_hash2(diff, hash1, hash2)
    hash1[1].each do |key, value|
      if hash2[1].class == Hash
        if hash1[1][key].class != Hash
          diff.push("no '#{key}' of '#{hash1[0]}' in '#{hash2[0]}'") unless hash2[1].key?(key)
        else
          no_hash1_keys_in_hash2(diff, [hash1[0], hash1[1][key]], [hash2[0], hash2[1][key]])
        end
      end
    end
  end
end
