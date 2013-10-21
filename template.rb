# Gems
# ==================================================

# Database
# ==================================================
#if yes?('Use sqlite3?')
#  use_database = true
#end

#if yes?('Use mysql?')
#  comment_lines 'Gemfile', "gem 'sqlite3'"
#  gem 'mysql2'
#end
#if yes?('Use postgresql?')
#  comment_lines 'Gemfile', "gem 'sqlite3'"
#  gem 'pg'
#end

repo_url = 'https://raw.github.com/patorash/rails_startup_template/master'

# Segment.io as an analytics solution (https://github.com/segmentio/analytics-ruby)
gem "analytics-ruby"
# For encrypted password
uncomment_lines 'Gemfile', "gem 'bcrypt-ruby'"
# Useful SASS mixins (http://bourbon.io/)
gem "bourbon"

# i18n-js
gem 'i18n-js'

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

if yes?("Would you like to install whenever?")
  gem 'whenever', require: false
end

if yes?("Use Bootstrap?")
  uncomment_lines 'Gemfile', "gem 'therubyracer'"
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
  # Rspec for tests (https://github.com/rspec/rspec-rails)
  gem "rspec-rails"
  # Capybara for integration testing (https://github.com/jnicklas/capybara)
  gem "capybara"
  gem "capybara-webkit"
  gem 'debugger'
end

gem_group :development do
  # Guard for automatically launching your specs when files are modified. (https://github.com/guard/guard-rspec)
  gem "guard-rspec"
  gem 'better_errors'
  gem 'spring'
  gem 'capistrano', "~> 2.15.5"
  gem 'capistrano_colors'
  gem 'capistrano-ext'
  gem 'capistrano-rbenv'
  gem 'pry-rails'
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
  uncomment_lines 'Gemfile', "gem 'unicorn'"
  use_unicorn = true
end
run "bundle install"

if use_unicorn
  get_and_gsub "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'
  run "echo 'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb' >> Procfile"
else
  run "echo 'web: bundle exec rails server -p $PORT' >> Procfile"
end
run "echo 'PORT: 3000' >> .foreman"
# We need this with foreman to see log output immediately
environment 'STDOUT.sync = true', env: 'development'


# Initialize Devise
# ==================================================
if use_devise
  generate 'devise:install'
  generate 'devise:views', 'users'
  environment 'config.action_mailer.default_url_options = {host: "localhost:3000"}', env: 'development'
  environment 'config.action_mailer.default_url_options = {host: "localhost:3000"}', env: 'test'
  route "devise_for :user"
end

# Initialize CanCan
# ==================================================
generate 'cancan:ability'

# Initialize Bootstrap
# ==================================================
if use_bootstrap
  generate 'bootstrap:install', 'less'
  if yes?("Responsive layout?")
    generate 'bootstrap:layout', 'application fluid'
  else
    generate 'bootstrap:layout', 'application fixed'
  end
  generate 'simple_form:install', '--bootstrap'
end



# Initialize rspec
# ==================================================
generate 'rspec:install'
remove_dir 'test'

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
remove_file '.gitignore'
create_file '.gitignore' do
  body = <<EOS
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
.foreman
EOS
end

generate 'controller', 'home index'
route "root to: 'home#index'"

#capistrano
capify!
uncomment_lines 'Capfile', "load 'deploy/assets'"
get_and_gsub "#{repo_url}/config/deploy.rb", 'config/deploy.rb'

# i18n-js
rake('i18n:js:setup')


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
