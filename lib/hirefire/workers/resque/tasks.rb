# encoding: utf-8

require 'resque/tasks'

task 'resque:setup' => :environment do
  ENV['QUEUE'] ||= '*'
end

desc 'Alias for the rake task "resque:work", this is required for Heroku.'
task 'jobs:work' => 'resque:work'
