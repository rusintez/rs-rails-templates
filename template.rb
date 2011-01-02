apply "https://github.com/rusintez/rs-rails-templates/raw/master/base.rb"

if yes?("Basecamp auth ?= devise + subdomains + invites")
  apply "https://github.com/rusintez/rs-rails-templates/raw/master/bcla.rb"
end

if yes?("Install authentication?")
  apply "https://github.com/rusintez/rs-rails-templates/raw/master/auth.rb"
end