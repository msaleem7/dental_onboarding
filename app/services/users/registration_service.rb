module Users
  module RegistrationService
    def self.call(params)
      user = User.new(params)
      user.role = Users::Roles::CANDIDATE
      user.save
      user
    end
  end
end
