# encoding: utf-8

module HireFire
  module Workers
    autoload :DelayedJob, 'hirefire/workers/delayed_job'
    autoload :Resque,     'hirefire/workers/resque'
  end
end
