class LocalesTest < ActionController::TestCase
  test "have same keys" do
    locales = {}
    Settings.available_locales.each do |locale|
      locales[locale] = YAML.load(File.read("config/locales/#{locale}.yml"))[locale]
    end
    locales.each do |locale1, locales1|
      locales.each do |locale2, locales2|
        next if locale1 == locale2
        diff = []
        compare_hash_by_keys(
          diff,
          [locale1, locales1],
          [locale2, locales2]
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
    hash1[1].each do |key, value|
      if hash2[1].class == Hash
        if hash1[1][key].class != Hash
          unless hash2[1].key?(key)
            diff.push("no '#{key}' of '#{hash1[0]}' in '#{hash2[0]}'")
          end
        else
          no_hash1_keys_in_hash2(
            diff,
            [hash1[0], hash1[1][key]], [hash2[0], hash2[1][key]]
          )
        end
      end
    end
  end
end
