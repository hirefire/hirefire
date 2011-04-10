# encoding: utf-8

module HireFire
  class Configuration

    ##
    # Contains the max amount of workers that are allowed to run concurrently
    #
    # @return [Fixnum] default: 1
    attr_accessor :max_workers

    ##
    # Contains the job/worker ratio which determines
    # how many workers need to be running depending on
    # the amount of pending jobs
    #
    # @return [Array] containing one or more hashes
    attr_accessor :job_worker_ratio

    ##
    # Default is nil, in which case it'll auto-detect either :heroku or :noop,
    # depending on the environment. It will never use :local, unless explicitly defined by the user.
    #
    # @param [Symbol, nil] environment Contains the name of the environment to run in.
    # @return [Symbol, nil] default: nil
    attr_accessor :environment

    ##
    # Instantiates a new HireFire::Configuration object
    # with the default configuration. These default configurations
    # may be overwritten using the HireFire.configure class method
    #
    # @return [HireFire::Configuration]
    def initialize
      @max_workers      = 1
      @job_worker_ratio = [
          { :jobs => 1,   :workers => 1 },
          { :jobs => 25,  :workers => 2 },
          { :jobs => 50,  :workers => 3 },
          { :jobs => 75,  :workers => 4 },
          { :jobs => 100, :workers => 5 }
        ]
    end

  end
end
