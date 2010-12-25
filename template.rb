apply "https://github.com/rusintez/rs-rails-templates/raw/master/base.rb"

if yes?("Install authentication?")
  apply "https://github.com/rusintez/rs-rails-templates/raw/master/auth.rb"
end