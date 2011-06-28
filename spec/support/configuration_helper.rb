# encoding: utf-8

module ConfigurationHelper
  def configure(&block)
    HireFire.configure(&block)
  end

  def with_configuration(&block)
    old_configuration = HireFire.configuration
    HireFire.configuration = HireFire::Configuration.new
    yield(HireFire.configuration)
  ensure
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

RSpec.configure do |config|
  config.include ConfigurationHelper
end
