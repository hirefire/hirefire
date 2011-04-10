HireFire - The Heroku Worker Manager
====================================

**HireFire automatically "hires" and "fires" (aka "scales") Delayed Job workers on Heroku**. When there are no queue jobs, HireFire will fire (shut down) all workers. If there are queued jobs, then it'll hire (spin up) workers. The amount of workers that get hired depends on the amount of queued jobs (the ratio can be configured by you). HireFire is great for both high, mid and low traffic applications. It can save you a lot of money by only hiring workers when there are pending jobs, and then firing them again once all the jobs have been processed. It's also capable to dramatically reducing processing time by automatically hiring more workers when the queue size increases.

**Low traffic example** say we have a small application that doesn't process for more than 2 hours in the background a month. Meanwhile, your worker is basically just idle the rest of the 718 hours in that month. Keeping that idle worker running costs $36/month ($0.05/hour). But, for the resources you're actually **making use of** (2 hours a month), you should be paying $0.10/month, not $36/month. This is what HireFire is for.

**High traffic example** say we have a high traffic application that needs to process a lot of jobs. There may be "traffic spikes" from time to time. In this case you can take advantage of the **job\_worker\_ratio**. Since this is application-specific, HireFire allows you to define how many workers there should be running, depending on the amount of queued jobs there are (see example configuration below). HireFire will then spin up more workers as traffic increases so it can work through the queue faster, then when the jobs are all finished, it'll shut down all the workers again until the next job gets queued (in which case it'll start with only a single worker again).

**Enough with the examples!** Read on to see how to set it, and configure it to your scaling and money saving needs.

Author
------

**Michael van Rooijen ( [@meskyanichi](http://twitter.com/#!/meskyanichi) )**

Drop me a message for any questions, suggestions, requests, bugs or submit them to the [issue log](https://github.com/meskyanichi/hirefire/issues).


Setting it up
-------------

A painless process. In a Ruby on Rails environment you would do something like this.

**Rails.root/Gemfile**

    gem 'rails'
    gem 'delayed_job'
    gem 'hirefire'

**(The order is important: Delayed Job > HireFire)**

That's it. Next time you deploy to [Heroku](http://heroku.com/) it'll automatically hire and fire your workers. Now, there are defaults, but I highly recommend you configure it since it only takes a few seconds. Create an initializer file:

**Rails.root/config/initializers/hirefire.rb**

    HireFire.configure do |config|
      config.max_workers      = 5 # default is 1
      config.job_worker_ratio = [
          { :jobs => 1,   :workers => 1 },
          { :jobs => 15,  :workers => 2 },
          { :jobs => 35,  :workers => 3 },
          { :jobs => 60,  :workers => 4 },
          { :jobs => 80,  :workers => 5 }
        ]
    end

Basically what it comes down to is that we say **NEVER** to hire more than 5 workers at a time (`config.max_workers = 5`). And then we define an array of hashes that represents our **job\_worker\_ratio**. In the above example we are basically saying:

* Hire 1 worker if there are 1-14 queued jobs
* Hire 2 workers if there are 15-34 queued jobs
* Hire 3 workers if there are 35-59 queued jobs
* Hire 4 workers if there are 60-79 queued jobs
* Hire 5 workers if there are more than 80 queued jobs

Once all the jobs in the queue have been processed, it'll fire (shut down) all the workers and start with a single worker the next time a new job gets queued. And then the next time the queue hits 15 jobs mark, in which case the single worker isn't fast enough on it's own, it'll spin up the 2nd worker again.


In a non-Ruby on Rails environment
----------------------------------

Almost the same setup, except that you have to initialize HireFire yourself after Delayed Job is done loading.

    require 'delayed_job'
    require 'hirefire'
    HireFire::Initializer.initialize!

**(Again, the order is important: Delayed Job > HireFire)**

If all goes well you should see a message similar to this when you boot your application:

    [HireFire] Delayed::Backend::ActiveRecord::Job detected!


Mapper Support
--------------

* [ActiveRecord ORM](https://github.com/rails/rails/tree/master/activerecord)
* [Mongoid ODM](https://github.com/mongoid/mongoid) (using [delayed_job_mongoid](https://github.com/collectiveidea/delayed_job_mongoid))


Worker Support
--------------

Currently only [Delayed Job](https://github.com/collectiveidea/delayed_job) with either [ActiveRecord ORM](https://github.com/rails/rails/tree/master/activerecord) and [Mongoid ODM](https://github.com/mongoid/mongoid).
Might have plans to implement this for other workers in the future.


Other potentially interesting gems
----------------------------------

* [Backup](https://github.com/meskyanichi/backup)
* [GitPusshuTen](https://github.com/meskyanichi/gitpusshuten)
* [Mongoid::Paperclip](https://github.com/meskyanichi/mongoid-paperclip)