# encoding: utf-8

##
# Load the "HireFire modified"
# Resque::Job and Resque::Worker classes
require File.dirname(__FILE__) + '/resque/job'
require File.dirname(__FILE__) + '/resque/worker'

##
# HireFire
# This is a HireFire modified version of
# the official Resque module
module ::Resque
  def self.enqueue(klass, *args)
    Job.create(queue_from_class(klass), klass, *args)

    ##
    # HireFire Hook
    # After a new job gets enqueued we check to see if there are currently
    # any workers up and running. If this is the case then we do nothing and
    # let the worker pick up the jobs (and potentially hire more workers)
    #
    # If there are no workers, then we manually hire workers.
    if ::Resque::Job.workers == 0
      ::Resque::Job.environment.hire
    end

    Plugin.after_enqueue_hooks(klass).each do |hook|
      klass.send(hook, *args)
    end
  end
end
