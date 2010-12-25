run "echo DEVISE SETUP"

name = ask("What do you want a user to be called?")

run 'rails generate devise:install'

inject_into_file 'config/environments/development.rb', :before => "end" do
  <<-RUBY
  
    config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  RUBY
end

generate "controller static home"
generate "devise #{name}"
generate "devise:views"

remove_file 'config/routes.rb'

file 'config/routes.rb', <<-RB
#{app_name.camelize}::Application.routes.draw do
  devise_for :#{name.pluralize} do
    get "login", :to => "devise/sessions#new"
    get "logout", :to => "devise/sessions#destroy"
    get "register", :to => "devise/registrations#new"
    get "profile", :to => "devise/registrations#edit"
  end
  root :to => 'static#home'
  get "static/home"
end
RB

rake "db:migrate"

git :add => ".", :commit => "-m 'auth added'"