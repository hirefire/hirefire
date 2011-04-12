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
    # After a new job gets queued, we command the current environment
    # to calculate the amount of workers we need to process the jobs
    # that are currently queued, and hire them accordingly.
    ::Resque::Job.environment.hire

    Plugin.after_enqueue_hooks(klass).each do |hook|
      klass.send(hook, *args)
    end
  end
end
