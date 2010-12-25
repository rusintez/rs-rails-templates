remove_file "public/robots.txt"
remove_file "public/index.html"
remove_file "public/images/rails.png"
remove_file "app/views/layouts/application.html.erb"
remove_file "public/javascripts/controls.js"
remove_file "public/javascripts/dragdrop.js"
remove_file "public/javascripts/effects.js"
remove_file "public/javascripts/prototype.js"
remove_file "public/javascripts/rails.js"
remove_file ".gitignore"


gem 'haml'
gem 'haml-rails'
gem 'paperclip'
gem 'devise'
gem 'hpricot'
gem 'simple-navigation'
gem 'ruby_parser'
gem 'thin'
gem 'will_paginate', '~> 3.0.beta'
gem 'jquery-rails'

bundle_if_dev_or_edge

generate "jquery:install"
generate "navigation_config"

# application layout

file "app/views/layouts/application.html.haml", <<-END
!!!
%html
  %head
    %title= yield(:title)
    %meta= yield(:description)
    = stylesheet_link_tag :all
    = javascript_include_tag :defaults
    = csrf_meta_tag
  %body
    #page
      #header
      #content= yield
      #footer
END


#helpers

remove_file 'app/helpers/application_helper.rb'

file 'app/helpers/application_helper.rb', <<-RUBY.gsub(/^ {2}/, '')
  module ApplicationHelper

    # Help individual pages to set their HTML titles
    def title(text)
      content_for(:title) { text }
    end

    # Help individual pages to set their HTML meta descriptions
    def description(text)
      content_for(:description) { text }
    end

  end
RUBY

# Use inside forms like this:
#
# = form_for @user do |f|
#   = render '/shared/error_messages', :target => @user
file 'app/views/shared/_error_messages.html.haml', <<-HAML.gsub(/^ {2}/, '')
  - if target.errors.any?
    #errorExplanation
      %h2
        = pluralize(target.errors.count, "error")
        prohibited this record from being saved:
      %ul
        - target.errors.full_messages.each do |msg|
          %li= msg
HAML

# sass

inside('public/stylesheets') do
  run('mkdir sass')
end

inside('public/stylesheets/sass') do
  file "application.sass", <<-END
#application sass
END
end

# ban spiders

file "public/robots.txt", <<-END
# To ban all spiders from the entire site uncomment the next two lines:
User-Agent: *
Disallow: /
END

# app config

gsub_file 'config/application.rb', /:password/, ':password, :password_confirmation'
gsub_file 'config/application.rb', /# config.autoload_paths/, 'config.autoload_paths'

inject_into_file 'config/application.rb', :before => "  end\nend" do
  <<-RUBY

    # Turn off timestamped migrations
    config.active_record.timestamped_migrations = false
  RUBY
end

inject_into_file 'config/application.rb', :before => "  end\nend" do
  <<-RUBY

    # Rotate log files (50 files max at 1MB each)
    config.logger = Logger.new(config.paths.log.first, 50, 1048576)
  RUBY
end

gsub_file 'config/environments/development.rb', /config.action_mailer.raise_delivery_errors = false/ do
  "# config.action_mailer.raise_delivery_errors = false"
end

# git

git :init => '-q'

file ".gitignore", <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
public/system/*
END

run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run "cp config/database.yml config/example_database.yml"

git :add => ".", :commit => "-m 'initial commit' -q"
