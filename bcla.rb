name = ask("What do you want a user to be called?").downcase
account = ask("Waht do you want an account to be called?").downcase

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

config.allow_account_sign_up = true

RUBY
end

generate "controller static home"
generate "devise #{name}"
generate "devise:views"

gem "devise_invitable"

run "bundle install"

generate "devise_invitable:install"
generate "devise_invitable #{name}"
generate "devise_invitable:views"

generate "scaffold #{account} name:string url:string"
generate "scaffold #{account}_membership #{name}:references #{account}:references role:string"

inject_into_file "app/models/#{name}.rb", :before => "\nend" do
<<-RUBY

attr_accessible :#{account}_name, :#{account}_url

has_many :#{account}_memberships
has_many :#{account.pluralize}, :through => :#{account}_memberships

validates_uniqueness_of  :email, :case_sensitive => false

attr_accessor :#{account}_name, :#{account}_url

validates_presence_of :#{account}_name, :on => :create
validates_presence_of :#{account}_name, :on => :create, :message => "#{account.capitalize} url should be unique and not blank."

before_validation :allow_sign_up, :on => :create
before_validation :check_#{account}, :on => :create

after_create  :create_#{account}
    
private

def allow_sign_up
  #{account.camelize}::CAN_SIGN_UP
end

def check_#{account}
  #{account} = #{account.camelize}.new(:name => self.#{account}_name, :url => self.#{account}_url)  
  unless #{account}.valid?
    self.#{account}_url = ""
  end
end

def create_#{account}
  #{account} = #{account.camelize}.find_by_url(self.#{account}_url)
  if #{account}.nil? # account is new
    #{account} = #{account.camelize}.create!(:name => self.#{account}_name, :url => self.#{account}_url)
    membership = #{account.camelize}Membership.create!(:#{account} => #{account}, :#{name} => self, :role => "owner")
    self.#{account}_memberships << membership
  else 
    # account_already_exists
    # do nothing, because if someone invited a user, it automatically should create rules
  end
end

RUBY
end

inject_into_file "app/models/#{account}.rb", :before => "\nend" do
<<-RUBY

  has_many :#{account}_memberships
  has_many :#{name}, :through => :#{account}_memberships
  
  validates_uniqueness_of :url, :case_sensitive => false
  validates_presence_of :url
  validates_presence_of :name
  
  CAN_SIGN_UP = Rails.application.config.allow_account_sign_up
  
  def role(#{name})
    #{account.camelize}Membership.find_by_#{account}_id_and_#{name}_id(self, #{name}).role
  end
  
RUBY
end

remove_file "app/controllers/#{account.pluralize}_controller.rb"

file "app/controllers/#{account.pluralize}_controller.rb", <<-RB
  class #{account.pluralize.camelize}Controller < ApplicationController

    before_filter :authenticate_#{name}!
    respond_to :html

    def index
      @#{account.pluralize} = #{account.camelize}.all
      respond_with(@#{account.pluralize})
    end

    def show
      @#{account} = #{account.camelize}.find_by_url!(request.subdomain)
      respond_with(@#{account})
    end

    def new
      @#{account} = #{account.camelize}.new
      respond_with(@#{account})
    end

    def edit
      @#{account} = #{account.camelize}.find(params[:id])
      respond_with(@#{account})
    end

    def create
      @#{account} = #{account.camelize}.new(params[:#{account}])
      if @#{account}.save
        flash[:notice] = '#{account.camelize} was successfully created.'
      end
      redirect_to current_#{name}
    end

    def update
      @#{account} = #{account.camelize}.find(params[:id])
      if @#{account}.update_attributes(params[:#{account}])
        flash[:notice] = '#{account.camelize} was successfully updated.'
      end
      respond_with(@#{account})
    end

    def destroy
      @#{account} = #{account.camelize}.find(params[:id])
      @#{account}.destroy
      flash[:notice] = "Sucessfully destroyed #{account}."
      redirect_to current_user
    end  
  end
RB

inject_into_file 'app/controllers/application_controller.rb', :before => "\nend" do
<<-RUBY

  include UrlHelper
RUBY
end

file 'app/helpers/url_helper.rb', <<-RB
module UrlHelper
  def with_subdomain(subdomain)
    subdomain = (subdomain || "")
    subdomain += "." unless subdomain.empty?
    [subdomain, request.domain, request.port_string].join
  end
  
  def url_for(options = nil)
    if options.kind_of?(Hash) && options.has_key?(:subdomain)
      options[:host] = with_subdomain(options.delete(:subdomain))
    end
    super
  end
end
RB

file 'lib/subdomain.rb', <<-RB
class Subdomain
  def self.matches?(request)
    request.subdomain.present? && request.subdomain != "www"
  end
end
RB

remove_file "config/routes.rb"

file 'config/routes.rb', <<-RB
require 'subdomain'

#{app_name.camelize}::Application.routes.draw do

  resources :#{account.pluralize}
  
  devise_for :#{name.pluralize}, :skip => [:registrations, :sessions] do
    get 'register' => 'devise/registrations#new', :as => :new_#{name}_registration
    post 'register' => 'devise/registrations#create', :as => :#{name}_registration
    get 'profile' => 'devise/registrations#edit', :as => :edit_#{name}_registration
    put 'profile' => 'devise/registrations#update', :as => :#{name}_registration
    get 'cancel' => 'devise/registrations#cancel', :as => :cancel_#{name}_registration
    delete 'cancel' => 'devise/registrations#destroy'
    get 'login' => 'devise/sessions#new', :as => :new_#{name}_session
    post 'login' => 'devise/sessions#create', :as => :#{name}_session
    get 'logout' => 'devise/sessions#destroy', :as => :destroy_#{name}_session
  end
  
  constraints(Subdomain) do
    match '/' => "#{account.pluralize}#show"
  end
  
  root :to => 'static#home'
  
end
RB

rake "db:migrate"

git :add => ".", :commit => "-m 'basecamp like authentication added added'"