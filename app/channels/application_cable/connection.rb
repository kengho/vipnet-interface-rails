class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :current_user

  def connect
    self.current_user = find_verified_user
  end

  private

    def find_verified_user
      # https://github.com/binarylogic/authlogic/blob/7c03eb79df7f0b05fe3fe1ea13d097ab9c92452f/test/test_helper.rb#L181
      persistence_token = cookies[:user_credentials][/[0-9a-f]+/]
      verified_user = User.find_by(persistence_token: persistence_token)
      if verified_user
        verified_user
      else
        reject_unauthorized_connection
      end
    end
end
