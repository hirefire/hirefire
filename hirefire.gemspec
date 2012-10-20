# encoding: utf-8

$:.push File.expand_path('../lib', __FILE__)
require 'hirefire/version'

Gem::Specification.new do |gem|

  ##
  # General configuration / information
  gem.name        = 'hirefire'
  gem.version     = HireFire::Version.current
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://rubygems.org/gems/hirefire'
  gem.summary     = %|HireFire automatically "hires" and "fires" (aka "scales") Delayed Job and Resque workers on Heroku.|
  gem.description = %|HireFire automatically "hires" and "fires" (aka "scales") Delayed Job and Resque workers on Heroku. When there are no queue jobs, HireFire will fire (shut down) all workers. If there are queued jobs, then it'll hire (spin up) workers. The amount of workers that get hired depends on the amount of queued jobs (the ratio can be configured by you). HireFire is great for both high, mid and low traffic applications. It can save you a lot of money by only hiring workers when there are pending jobs, and then firing them again once all the jobs have been processed. It's also capable to dramatically reducing processing time by automatically hiring more workers when the queue size increases.|

  ##
  # Files and folder that need to be compiled in to the Ruby Gem
  gem.files         = %x[git ls-files].split("\n")
  gem.test_files    = %x[git ls-files -- {spec}/*].split("\n")
  gem.require_path  = 'lib'

  ##
  # Production gem dependencies
  gem.add_dependency 'heroku-api', ['-> 0.3.5']
  gem.add_dependency 'rush',   ['~> 0.6.7']

end
