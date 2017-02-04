class VidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value =~ /\A0x[0-9a-f]{8}\z/
    record.errors[attribute] << (options[:message] || "vid is not a valid")
  end
end
