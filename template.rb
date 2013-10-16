# Gems
# ==================================================

# Segment.io as an analytics solution (https://github.com/segmentio/analytics-ruby)
gem "analytics-ruby"
# For encrypted password
gem "bcrypt-ruby"
# Useful SASS mixins (http://bourbon.io/)
gem "bourbon"

# For authorization (https://github.com/ryanb/cancan)
gem "cancan"
if yes?('Use devise?')
  gem 'devise'
  use_devise = true
end

gem 'kaminari'
gem 'ransack'
gem 'ancestry'
gem 'active_decorator'
gem 'whenever', require: false

if yes?("Use Bootstrap?")
  gem 'therubyracer', platforms: :ruby
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
  use_bootstrap = true
end

# HAML templating language (http://haml.info)
#gem "haml-rails" if yes?("Use HAML instead of ERB?")
gem 'slim-rails' if yes?("Use slim instead of ERB?")


# Simple form builder (https://github.com/plataformatec/simple_form)
#gem "simple_form", git: "https://github.com/plataformatec/simple_form"
gem "simple_form", github: 'plataformatec/simple_form', branch: 'master'
# To generate UUIDs, useful for various things
gem "uuidtools"

gem_group :development, :test do
  gem "rspec-rails"
  # Capybara for integration testing (https://github.com/jnicklas/capybara)
  gem "capybara"
  gem "capybara-webkit"
  gem 'debugger'
end

gem_group :development do
  # Rspec for tests (https://github.com/rspec/rspec-rails)
  gem "rspec-rails"
  # Guard for automatically launching your specs when files are modified. (https://github.com/guard/guard-rspec)
  gem "guard-rspec"
  gem 'better_errors'
  gem 'spring'
  gem 'capistrano', "~> 2.15.5"
  gem 'capistrano_colors'
  gem 'capistrano-ext'
  gem 'capistrano-rbenv'
end

gem_group :test do
  gem 'database_cleaner'
  gem 'launchy'
  gem 'rb-fsevent', require: false
  gem 'growl'
  # FactoryGirl instead of Rails fixtures (https://github.com/thoughtbot/factory_girl)
  gem "factory_girl_rails"
  gem 'simplecov', require: false
  gem 'webmock', require: 'webmock/rspec'
end

gem_group :production do
  # For Rails 4 deployment on Heroku
  gem "rails_12factor"
end


# Setting up foreman to deal with environment variables and services
# https://github.com/ddollar/foreman
# ==================================================
# Use Procfile for foreman
if yes?('Use unicorn?')
  gem 'unicorn'
  run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn.conf.rb' >> Procfile"
else
  run "echo 'web: bundle exec rails server -p $PORT' >> Procfile"
end

run "echo PORT=3000 >> .foreman"
run "echo '.foreman' >> .gitignore"
# We need this with foreman to see log output immediately
run "echo 'STDOUT.sync = true' >> config/environments/development.rb"

run "bundle install"

# Initialize Devise
# ==================================================
if use_devise
  run "rails g devise:install"
  run "rails g devise user"
  run "rails g devise:views"
  run "echo 'config.action_mailer.default_url_options = { :host => 'localhost:3000' }' >> config/environments/development.rb"
end

# Initialize CanCan
# ==================================================
run "rails g cancan:ability"

# Initialize Bootstrap
# ==================================================
if use_bootstrap
  run "rails g bootstrap:install less"
  if yes?("Responsive layout?")
    run "rails g bootstrap:layout application fluid"
  else
    run "rails g bootstrap:layout application fixed"
  end
  run "rails g simple_form:install --bootstrap"
end



# Initialize rspec
# ==================================================
run "rails g rspec:install"

# Initialize guard
# ==================================================
run "bundle exec guard init rspec"


# Clean up Assets
# ==================================================
# Use SASS extension for application.css
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
# Remove the require_tree directives from the SASS and JavaScript files. 
# It's better design to import or require things manually.
run "sed -i '' /require_tree/d app/assets/javascripts/application.js"
run "sed -i '' /require_tree/d app/assets/stylesheets/application.css.scss"
# Add bourbon to stylesheet file
run "echo >> app/assets/stylesheets/application.css.scss"
run "echo '@import \"bourbon\";' >>  app/assets/stylesheets/application.css.scss"




# Bootstrap: install from https://github.com/twbs/bootstrap
# Note: This is 3.0.0
# ==================================================
#if yes?("Download bootstrap?")
#  run "wget https://github.com/twbs/bootstrap/archive/v3.0.0.zip -O bootstrap.zip -O bootstrap.zip"
#  run "unzip bootstrap.zip -d bootstrap && rm bootstrap.zip"
#  run "cp bootstrap/bootstrap-3.0.0/dist/css/bootstrap.css vendor/assets/stylesheets/"
#  run "cp bootstrap/bootstrap-3.0.0/dist/js/bootstrap.js vendor/assets/javascripts/"
#  run "rm -rf bootstrap"
#  run "echo '@import \"bootstrap\";' >>  app/assets/stylesheets/application.css.scss"
#  run "rails g simple_form:install --bootstrap"
#end


# Font-awesome: Install from http://fortawesome.github.io/Font-Awesome/
# ==================================================
if yes?("Download font-awesome?")
  run "wget http://fortawesome.github.io/Font-Awesome/assets/font-awesome.zip -O font-awesome.zip"
  run "unzip font-awesome.zip && rm font-awesome.zip"
  run "cp font-awesome/css/font-awesome.css vendor/assets/stylesheets/"
  run "cp -r font-awesome/font public/font"
  run "rm -rf font-awesome"
  run "echo '@import \"font-awesome\";' >>  app/assets/stylesheets/application.css.scss"
end


# Ignore rails doc files, Vim/Emacs swap files, .DS_Store, and more
# ===================================================
run "cat << EOF >> .gitignore
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
database.yml
doc/
*.swp
*~
.project
.idea
.secret
.DS_Store
EOF"


route "root to: 'welcome#index'"

# Git: Initialize
# ==================================================
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }

if yes?("Initialize GitHub repository?")
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say "Repository already exists:"
    say "#{git_uri}"
  else
    username = ask "What is your GitHub username?"
    run "curl -u #{username} -d '{\"name\":\"#{app_name}\"}' https://api.github.com/user/repos"
    git remote: %Q{ add origin git@github.com:#{username}/#{app_name}.git }
    git push: %Q{ origin master }
  end
end
