name = ask("What do you want a user to be called?")

run 'rails generate devise:install'

inject_into_file 'config/environments/development.rb', :before => "\nend" do
<<-RUBY
  
config.action_mailer.default_url_options = { :host => 'localhost:3000' }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => 'localhost',
  :user_name            => 'user_name',
  :password             => 'user_pass',
  :authentication       => 'plain',
  :enable_starttls_auto => true  }

RUBY
end

generate "controller static home"
generate "devise #{name}"
generate "devise:views"

if yes?("Install invitable logic for #{name.capitalize}?")
  gem "devise_invitable"
  run "bundle install"
  generate "devise_invitable:install"
  generate "devise_invitable #{name}"
  generate "devise_invitable:views"
end

remove_file "config/routes.rb"

file 'config/routes.rb', <<-RB
#{app_name.camelize}::Application.routes.draw do

  #devise_for :#{name.pluralize.downcase} do
  #  get "login", :to => "devise/sessions#new"
  #  get "logout", :to => "devise/sessions#destroy"
  #  get "register", :to => "devise/registrations#new"
  #  get "profile", :to => "devise/registrations#edit"
  #end
  #devise_for :#{name.pluralize.downcase}, :as => '', :path_names => { :sign_in => "login", :sign_out => "logout", :sign_up => "register", :edit => "profile"}
  
  devise_for :#{name.pluralize.downcase}, :skip => [:registrations, :sessions] do
    # devise/registrations
    get 'register' => 'devise/registrations#new', :as => :new_user_registration
    post 'register' => 'devise/registrations#create', :as => :user_registration
    get 'profile' => 'devise/registrations#edit', :as => :edit_user_registration
    put 'profile' => 'devise/registrations#update', :as => :user_registration
    
    get 'cancel' => 'devise/registrations#cancel', :as => :cancel_user_registration
    delete 'cancel' => 'devise/registrations#destroy'

    # devise/sessions
    get 'login' => 'devise/sessions#new', :as => :new_user_session
    post 'login' => 'devise/sessions#create', :as => :user_session
    get 'logout' => 'devise/sessions#destroy', :as => :destroy_user_session
  end
  
  root :to => 'static#home'
  get "static/home"
  
end
RB

rake "db:migrate"

git :add => ".", :commit => "-m 'auth added'"