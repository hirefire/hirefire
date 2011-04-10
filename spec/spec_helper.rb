# encoding: utf-8

##
# Path to the lib directory
LIB_PATH = File.expand_path('../../lib', __FILE__)

##
# Load the HireFire Ruby library
require File.join(LIB_PATH, 'hirefire')

##
# Use Mocha to mock with RSpec
RSpec.configure do |config|
  config.mock_with :mocha
end
