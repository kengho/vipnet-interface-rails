# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# http://stackoverflow.com/a/5458190
loop do
break
  STDOUT.puts "Enter administrator's email"
  email = STDIN.gets.strip
  STDOUT.puts "Enter administrator's password"
  # http://stackoverflow.com/a/15685054
  password = STDIN.noecho(&:gets).chomp
  STDOUT.puts "Enter password's confirmation"
  password_confirmation = STDIN.noecho(&:gets).chomp
  admin = User.new(email: email, password: password, password_confirmation: password_confirmation, role: "administrator")
  if admin.save
    STDOUT.puts "Administrator user successfully created"
    break
  else
    STDOUT.puts "Error creating administrator"
    STDOUT.puts ""
  end
end

GET_INFORMATION_TOKEN = SecureRandom.urlsafe_base64(64)
POST_HW_TOKEN = SecureRandom.urlsafe_base64(64)
POST_ADMINISTRATOR_TOKEN = SecureRandom.urlsafe_base64(64)
CHECKER_TOKEN = SecureRandom.urlsafe_base64(64)

STDOUT.puts "Please create .env file in root of this app (gem dotenv) or use some other method for storing ENV vars"
STDOUT.puts ""
STDOUT.puts "GET_INFORMATION_TOKEN=#{GET_INFORMATION_TOKEN}"
STDOUT.puts "POST_HW_TOKEN=#{POST_HW_TOKEN}"
STDOUT.puts "POST_ADMINISTRATOR_TOKEN=#{POST_ADMINISTRATOR_TOKEN}"
STDOUT.puts "CHECKER_TOKEN=#{CHECKER_TOKEN}"
STDOUT.puts ""
STDOUT.puts "(You may use your own tokens.)"

# default settings
# for some reason 'Setting.save_default(:some_key, "123")' doesn't work sometimes
support_email = Settings.new(var: "support_email", value: "")
support_email.save
checker = Settings.new(var: "checker", value: "http://localhost:8080/?ip=#\{ip}&token=#\{token}")
checker.save
nodes_per_page = Settings.new(var: "nodes_per_page", value: "10")
nodes_per_page.save
networks_to_ignore = Settings.new(var: "networks_to_ignore", value: "6670,6671")
networks_to_ignore.save
