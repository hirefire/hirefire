# encoding: utf-8
$:.unshift(File.expand_path('../', __FILE__))
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'hirefire'

module ConfigurationHelper
  
  def configure(&block)
    HireFire.configure(&block)
  end
  
  def with_configuration(&block)
    old_configuration = HireFire.configuration
    HireFire.configuration = HireFire::Configuration.new
    yield(HireFire.configuration)
    HireFire.configuration = old_configuration
  end
  
  def with_max_workers(workers, &block)
    with_configuration do |config|
      config.max_workers = workers
      yield
    end
  end
  
  def with_min_workers(workers, &block)
    with_configuration do |config|
      config.min_workers = workers
      yield
    end
  end
end

##
# Use Mocha to mock with RSpec
RSpec.configure do |config|
  config.mock_with :mocha
  config.include ConfigurationHelper
end
