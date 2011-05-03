# encoding: utf-8

require File.expand_path('../spec_helper', __FILE__)

module HireFire
  module Backend
    ##
    # Stub out backend interface inclusion
    # since it's irrelevant for these tests
    def self.included(base)
      base.send(:include, Environment::Stub)
    end
  end

  module Environment
    module Stub
      ##
      # Stubbed out since this normally comes from
      # a sub class like HireFire::Environment::Heroku or
      # HireFire::Environment::Local
      def workers(amount = nil)
        if amount.nil?
          @_workers ||= 0
          return @_workers
        end
      end

      ##
      # Allows the specs to stub the workers count
      # and return the desired amount
      def workers=(amount)
        @_workers = amount
        self.stubs(:workers).with.returns(amount)
      end

      ##
      # Returns the amount of jobs
      # Defaults to: 0
      def jobs
        @_jobs ||= 0
      end

      ##
      # Allows the specs to stub the queued job count
      # and return the desired amount
      def jobs=(amount)
        @_jobs = amount
        self.stubs(:jobs).returns(amount)
      end
    end
  end
end

describe HireFire::Environment::Base do

  let(:base) { HireFire::Environment::Base.new }

  describe 'testing the test setup' do
    it 'should default the queued job count to 0 for these specs' do
      base.jobs.should == 0
    end

    it 'should set the queued job count to 10' do
      base.jobs = 10
      base.jobs.should == 10
    end

    it 'should have zero workers by default' do
      base.workers.should == 0
    end

    it 'should set the amount of workers to 10' do
      base.workers = 10
      base.workers.should == 10
    end
  end

  describe '#fire' do
    it 'should not fire any workers when there are still jobs in the queue' do
      base.jobs    = 1
      base.workers = 1

      base.expects(:workers).with(0).never
      base.fire
    end

    it 'should not fire any workers if there arent any workers' do
      base.jobs    = 1
      base.workers = 0

      base.expects(:workers).with(0).never
      base.fire
    end

    it 'should fire all workers when there arent any jobs' do
      base.jobs    = 0
      base.workers = 1

      HireFire::Logger.expects(:message).with('All queued jobs have been processed. Firing all workers.')
      base.expects(:workers).with(0).once
      base.fire
    end

    it 'should set the workers to minimum workers when there arent any jobs' do
      with_min_workers(2) do
        base.jobs          = 0
        base.workers       = 10

        HireFire::Logger.expects(:message).with('All queued jobs have been processed. Setting workers to 2.')
        base.expects(:workers).with(2).once
        base.fire
      end
    end
  end

  describe '#hire' do
    describe 'the standard notation' do
      before do
        configure do |config|
          config.max_workers = 5
          config.job_worker_ratio = [
            { :jobs => 1,  :workers => 1 },
            { :jobs => 15, :workers => 2 },
            { :jobs => 30, :workers => 3 },
            { :jobs => 60, :workers => 4 },
            { :jobs => 90, :workers => 5 }
          ]
        end
      end

      it 'should request 1 worker' do
        base.jobs    = 1
        base.workers = 0

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 1 in total.')
        base.expects(:workers).with(1).once
        base.hire
      end

      it 'should not request 1 worker, since there already is one worker running' do
        base.jobs    = 5
        base.workers = 1

        base.expects(:workers).with(1).never
        base.hire
      end

      it 'should request 2 workers' do
        base.jobs    = 15
        base.workers = 0

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.')
        base.expects(:workers).with(2).once
        base.hire
      end

      it 'should request 2 workers' do
        base.jobs    = 20
        base.workers = 1

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.')
        base.expects(:workers).with(2).once
        base.hire
      end

      it 'should not request 2 workers since we already have 2' do
        base.jobs    = 25
        base.workers = 2

        base.expects(:workers).with(2).never
        base.hire
      end

      it 'should NEVER lower the worker amount from the #hire method' do
        base.jobs    = 25 # simulate that 5 jobs are already processed (30 - 5)
        base.workers = 3  # and 3 workers are hired

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.').never
        base.expects(:workers).with(2).never
        base.hire
      end

      it 'should NEVER hire more workers than the #max_workers' do
        with_max_workers(3) do
          base.jobs    = 100
          base.workers = 0

          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').once
          base.expects(:workers).with(3).once
          base.hire
        end
      end

      it 'should not hire 5 workers even if defined in the job/ratio, when the limit is 3, it should hire 3 max' do
        with_configuration do |config|
          config.max_workers = 3
          config.job_worker_ratio = [
            { :jobs => 5, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 0
          
          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').once
          base.expects(:workers).with(3).once
          base.hire
        end
      end

      it 'should not hire (or invoke) any more workers since the max amount allowed is already running' do
        with_configuration do |config|
          config.max_workers = 3
          config.job_worker_ratio = [
            { :jobs => 5, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 3

          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').never
          base.expects(:workers).with(3).never
          base.hire
        end
      end

      it 'the max_workers option can only "limit" the amount of max_workers when used in the "Standard Notation"' do
        with_configuration do |config|
          config.max_workers = 10
          config.job_worker_ratio = [
            { :jobs => 5, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 0

          HireFire::Logger.expects(:message).with('Hiring more workers so we have 5 in total.').once
          base.expects(:workers).with(5).once
          base.hire
        end
      end

      it 'should NEVER do API requests to Heroku if the max_workers are already running' do
        base.jobs    = 100
        base.workers = 5

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 5 in total.').never
        base.expects(:workers).with(5).never
        base.hire
      end

      it 'should NEVER do API requests to Heroku if the workers query returns nil' do
        base.jobs    = 100
        base.workers = nil

        base.expects(:log_and_hire).never
        base.expects(:fire).never
        base.hire
      end
    end

    describe 'the Lambda (functional) notation' do
      before do
        configure do |config|
          config.max_workers = 5
          config.job_worker_ratio = [
            { :when => lambda {|jobs| jobs < 15 }, :workers => 1 },
            { :when => lambda {|jobs| jobs < 30 }, :workers => 2 },
            { :when => lambda {|jobs| jobs < 60 }, :workers => 3 },
            { :when => lambda {|jobs| jobs < 90 }, :workers => 4 }
          ]
        end
      end

      it 'should request 1 worker' do
        base.jobs    = 1
        base.workers = 0

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 1 in total.')
        base.expects(:workers).with(1).once
        base.hire
      end

      it 'should not request 1 worker, since there already is one worker running' do
        base.jobs    = 5
        base.workers = 1

        base.expects(:workers).with(1).never
        base.hire
      end

      it 'should request 2 workers' do
        base.jobs    = 15
        base.workers = 0

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.')
        base.expects(:workers).with(2).once
        base.hire
      end

      it 'should request 2 workers' do
        base.jobs    = 20
        base.workers = 1

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.')
        base.expects(:workers).with(2).once
        base.hire
      end

      it 'should not request 2 workers since we already have 2' do
        base.jobs    = 25
        base.workers = 2

        base.expects(:workers).with(2).never
        base.hire
      end

      it 'should NEVER lower the worker amount from the #hire method' do
        base.jobs    = 25 # simulate that 5 jobs are already processed (30 - 5)
        base.workers = 3  # and 3 workers are hired

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 2 in total.').never
        base.expects(:workers).with(2).never
        base.hire
      end

      it 'should NEVER hire more workers than the #max_workers' do
        with_configuration do |config|
          config.max_workers = 3
          base.jobs    = 100
          base.workers = 0
          
          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').once
          base.expects(:workers).with(3).once
          base.hire
        end
      end

      it 'should not hire 5 workers even if defined in the job/ratio, when the limit is 3, it should hire 3 max' do
        with_configuration do |config|
          config.max_workers = 3
          config.job_worker_ratio = [
            { :when => lambda { |jobs| jobs < 5 }, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 0
          
          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').once
          base.expects(:workers).with(3).once
          base.hire   
        end
      end

      it 'should not hire (or invoke) any more workers since the max amount allowed is already running' do
        with_configuration do |config|
          config.max_workers = 3
          config.job_worker_ratio = [
            { :when => lambda { |jobs| jobs < 5 }, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 3
          
          HireFire::Logger.expects(:message).with('Hiring more workers so we have 3 in total.').never
          base.expects(:workers).with(3).never
          base.hire
        end
      end

      it 'the max_workers option can only "limit" the amount of max_workers when used in the "Standard Notation"' do
        with_configuration do |config|
          config.max_workers = 10
          config.job_worker_ratio = [
            { :when => lambda { |jobs| jobs < 5 }, :workers => 5 }
          ]
          
          base.jobs    = 100
          base.workers = 0

          HireFire::Logger.expects(:message).with('Hiring more workers so we have 10 in total.').once
          base.expects(:workers).with(10).once
          base.hire
        end
      end

      it 'should NEVER do API requests to Heroku if the max_workers are already running' do
        base.jobs    = 100
        base.workers = 5

        HireFire::Logger.expects(:message).with('Hiring more workers so we have 5 in total.').never
        base.expects(:workers).with(5).never
        base.hire
      end
    end
  end
end
