# encoding: utf-8

##
# Load in the official Resque rake tasks
require 'resque/tasks'

##
# Overwrite the resque:setup rake task to first load
# in the application environment before proceeding
#
# ENV['QUEUE'] will default to '*' unless it's defined
# as an environment variable on Heroku or the Local machine
task 'resque:setup' => :environment do
  ENV['QUEUE'] ||= '*'
end

##
# This is an alias to the "resque:work" task since Heroku doesn't respond
# to "resque:work", we need to add this alias so Resque can be initialized by Heroku
desc 'Alias of "resque:work" - This is required for running on Heroku.'
task 'jobs:work' => 'resque:work'
