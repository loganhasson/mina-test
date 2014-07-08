require 'mina/bundler'
require 'mina/rails'
require 'mina/git'

set :domain,       "104.131.226.198"
set :deploy_to,    "/home/root/mina-test"
set :app_path,     "#{deploy_to}/#{current_path}"
set :repository,   "git@github.com:loganhasson/mina-test.git"
set :branch,       "master"
set :user,         "root"
set :shared_paths, ["application.yml"]

task :environment do
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/pids"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    invoke :'git:clone'
    invoke :'bundle:install'
    invoke :'deploy:link_shared_paths'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'

    to :launch do
      invoke :'unicorn:restart'
    end
  end
end

namespace :unicorn do
  desc "Restart unicorn"
  task :restart => :environment do
    queue "if kill -0 `cat #{deploy_to}/shared/pids/unicorn.pid`> /dev/null 2>&1; then kill -9 `cat #{deploy_to}/shared/pids/unicorn.pid`; else echo 'Unicorn is not running'; fi"
    queue "cd #{app_path} && unicorn -c config/unicorn.rb -D -E production"
  end
end
