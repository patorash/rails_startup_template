# -*- coding: utf-8 -*-
require "capistrano/ext/multistage"
require "bundler/capistrano"
require 'capistrano_colors'
load 'deploy/assets'
require 'capistrano-rbenv'
require "whenever/capistrano"
set :whenever_command, 'bundle exec whenever'

set :ruby_version, '2.0.0-p247'
set :ruby_env, 'rbenv'
set :rbenv_ruby_version, ruby_version

#set :repository,  "git@github.com:xxxxxx/xxxxxx.git"
#set :branch,      'master'
set :deploy_via,  :copy
set :scm, :git
set :user,"username"
set :use_sudo, false
set :bundle_without, [:development, :test]
set :keep_releases, 5
set :copy_strategy, :export
set :app_server, 'unicorn'

desc 'database.ymlのシンボリックリンクを張ります'
task :prepare_database_yml do
  run "ln -s #{shared_path}/database.yml #{release_path}/config/database.yml"
end

desc "プロジェクトに必要なyamlファイルの準備を行います"
task :prepare_yaml do
  run "cd #{release_path};RAILS_ENV=production PROJECT=#{application} bundle exec rake config:merge"
end

namespace :deploy do
  task :restart, :roles => :app, :except => { :no_release => true } do
    if app_server == 'passenger'
      run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
    else
      run "cd #{release_path};bundle exec rake unicorn:restart"
    end
  end
end

desc '.ruby-versionを作成'
task :make_ruby_version do
  run "cd #{release_path};echo '#{ruby_version}' > .ruby-version"
end

desc 'unicorn用のフォルダへのシンボリックリンクを張ります'
task :link_to_unicorn do
  run "mkdir -p #{shared_path}/sock;ln -s #{shared_path}/sock #{release_path}/tmp/sock"
end

desc 'unicorn用のsockフォルダを作成'
task :mkdir_sock do
  if app_server == 'unicorn'
    run "mkdir -p #{shared_path}/sock"
  end
end

desc "JavaScript用のi18nファイルを出力します"
task :i18n_js_export do
  run "cd #{release_path};RAILS_ENV=production bundle exec rake i18n:js:export"
end


task :after_update_code do
  make_ruby_version
  link_to_unicorn
end

after 'bundle:install', 'prepare_database_yml'
after 'prepare_database_yml', 'i18n_js_export'
after 'deploy:update_code', 'after_update_code'
after "deploy:restart", "deploy:cleanup"
after 'deploy:setup', 'mkdir_sock'