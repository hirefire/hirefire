# encoding: utf-8
$:.unshift(File.expand_path('../', __FILE__))
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'hirefire'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.expand_path('../support', __FILE__), '**/*.rb')].each {|f| require f}

##
# Use Mocha to mock with RSpec
RSpec.configure do |config|
  config.mock_with :mocha
end
