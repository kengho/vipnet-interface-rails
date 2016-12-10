# http://stackoverflow.com/a/5458190
loop do
  STDOUT.puts "Enter administrator's email"
  email = STDIN.gets.strip
  STDOUT.puts "Enter administrator's password"
  # http://stackoverflow.com/a/15685054
  password = STDIN.noecho(&:gets).chomp
  STDOUT.puts "Enter password's confirmation"
  password_confirmation = STDIN.noecho(&:gets).chomp
  admin = User.new(
    email: email,
    password: password,
    password_confirmation: password_confirmation,
    role: "administrator",
  )
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
POST_TICKETS_TOKEN = SecureRandom.urlsafe_base64(64)

STDOUT.puts "Please create .env file in root of this app (gem 'dotenv') or use some other method for storing ENV vars"
STDOUT.puts ""
STDOUT.puts "GET_INFORMATION_TOKEN=#{GET_INFORMATION_TOKEN}"
STDOUT.puts "POST_HW_TOKEN=#{POST_HW_TOKEN}"
STDOUT.puts "POST_ADMINISTRATOR_TOKEN=#{POST_ADMINISTRATOR_TOKEN}"
STDOUT.puts "CHECKER_TOKEN=#{CHECKER_TOKEN}"
STDOUT.puts "POST_TICKETS_TOKEN=#{POST_TICKETS_TOKEN}"
STDOUT.puts ""
STDOUT.puts "(You may use your own tokens.)"
STDOUT.puts ""

Settings.set_defaults

STDOUT.puts "All done. Enable needed functionality in /settings page"
