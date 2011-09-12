HireFire - The Heroku Worker Manager
====================================

**HireFire automatically "hires" and "fires" (aka "scales") [Delayed Job](https://github.com/collectiveidea/delayed_job) and [Resque](https://github.com/defunkt/resque) workers on Heroku**. When there are no queue jobs, HireFire will fire (shut down) all workers. If there are queued jobs, then it'll hire (spin up) workers. The amount of workers that get hired depends on the amount of queued jobs (the ratio can be configured by you). HireFire is great for both high, mid and low traffic applications. It can save you a lot of money by only hiring workers when there are pending jobs, and then firing them again once all the jobs have been processed. It's also capable to dramatically reducing processing time by automatically hiring more workers when the queue size increases.

**Low traffic example** say we have a small application that doesn't process for more than 2 hours in the background a month. Meanwhile, your worker is basically just idle the rest of the 718 hours in that month. Keeping that idle worker running costs $36/month ($0.05/hour). But, for the resources you're actually **making use of** (2 hours a month), you should be paying $0.10/month, not $36/month. This is what HireFire is for.

**High traffic example** say we have a high traffic application that needs to process a lot of jobs. There may be "traffic spikes" from time to time. In this case you can take advantage of the **job\_worker\_ratio**. Since this is application-specific, HireFire allows you to define how many workers there should be running, depending on the amount of queued jobs there are (see example configuration below). HireFire will then spin up more workers as traffic increases so it can work through the queue faster, then when the jobs are all finished, it'll shut down all the workers again until the next job gets queued (in which case it'll start with only a single worker again).

Author
------

**Michael van Rooijen ( [@meskyanichi](http://twitter.com/#!/meskyanichi) )**

Drop me a message for any questions, suggestions, requests, bugs or submit them to the [issue log](https://github.com/meskyanichi/hirefire/issues).


[HireFireApp.com](http://hirefireapp.com/) - The Heroku Process Manager
--------------------------------------------

**This is not part of the open source HireFire**

[HireFire](http://hirefireapp.com/)(Service) is a hosted service which is based on HireFire(Open Source). The reason this project came about is because of Heroku's platform constraints which made the Open Source project quite unstable/unreliable and reduced performance dramatically on HTTP requests (slow response times when new jobs are being queued). It is also hard to allow both worker as well as dyno scaling, and manage that from within the same process.

For this reason, I created a hosted web service, based on the open source project. Not only does it support **worker dyno scaling** but it also supports **web dyno scaling**. And next to Heroku's **Badious Bamboo** stack, it also supports Heroku's new stack, **Celadon Cedar**.

If you're looking to scale either your web or worker dynos, on either Badious Bamboo or Celadon Cedar, be sure to check out the HireFire hosted service.

**[http://hirefireapp.com](http://hirefireapp.com)**



Setting it up
-------------

A painless process. In a Ruby on Rails environment you would do something like this.

**Rails.root/Gemfile**

    gem 'rails'
    # gem 'delayed_job' # uncomment this line if you use Delayed Job
    # gem 'resque'      # uncomment this line if you use Resque
    gem 'hirefire'

**(The order is important: "Delayed Job" / "Resque" > HireFire)**

Be sure to add the following Heroku environment variables so HireFire can manage your workers.

    heroku config:add HIREFIRE_EMAIL=<your_email> HIREFIRE_PASSWORD=<your_password>

These are the same email and password credentials you use to log in to the Heroku web interface to manage your workers.

And that's it. Next time you deploy to [Heroku](http://heroku.com/) it'll automatically hire and fire your workers. Now, there are defaults, but I highly recommend you configure it since it only takes a few seconds. Create an initializer file:

**Rails.root/config/initializers/hirefire.rb**

    HireFire.configure do |config|
      config.environment      = nil # default in production is :heroku. default in development is :noop
      config.max_workers      = 5   # default is 1
      config.min_workers      = 0   # default is 0
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

*If you prefer a more functional way of defining your job/worker ratio, you could use the following notation style:*

    HireFire.configure do |config|
      config.max_workers = 5
      config.job_worker_ratio = [
        { :when => lambda {|jobs| jobs < 15 }, :workers => 1 },
        { :when => lambda {|jobs| jobs < 35 }, :workers => 2 },
        { :when => lambda {|jobs| jobs < 60 }, :workers => 3 },
        { :when => lambda {|jobs| jobs < 80 }, :workers => 4 }
      ]
    end

The above notation is slightly different, since now you basically define how many workers to hire when `jobs < n`. So for example if there are 80 or more jobs, it'll hire the `max_workers` amount, which is `5` in the above example. If you change the `max_workers = 5` to `max_workers = 10`, then if there are 80 or more jobs queued, it'll go from 4 to 10 workers.


In a non-Ruby on Rails environment
----------------------------------

Almost the same setup, except that you have to initialize HireFire yourself after Delayed Job or Resque is done loading.

    require 'delayed_job'
    # require 'delayed_job' # uncomment this line if you use Delayed Job
    # require 'resque'      # uncomment this line if you use Resque
    HireFire::Initializer.initialize!

**(Again, the order is important: "Delayed Job" / "Resque" > HireFire)**

If all goes well you should see a message similar to this when you boot your application:

    [HireFire] Delayed::Backend::ActiveRecord::Job detected!


Worker / Mapper Support
--------------

HireFire currently works with the following worker and mapper libraries:

- [Delayed Job](https://github.com/collectiveidea/delayed_job)
  - [ActiveRecord ORM](https://github.com/rails/rails/tree/master/activerecord)
  - [Mongoid ODM](https://github.com/mongoid/mongoid) (using [delayed_job_mongoid](https://github.com/collectiveidea/delayed_job_mongoid))

- [Resque](https://github.com/defunkt/resque)
  - [Redis](https://github.com/ezmobius/redis-rb)


Suggestions, Bugs, Requests, Questions
--------------------------------------

View the [issue log](https://github.com/meskyanichi/hirefire/issues) and post them there.


Contributors
------------

<table>
  <tr>
    <th>Contributor</th>
    <th>Contribution</th>
  </tr>
  <tr>
    <td><a href="https://github.com/dirk" target="_blank">Dirk Gadsden ( dirk )</a></td>
    <td>Implementing a more functional job/worker ratio notation using Lambda</td>
  </tr>
  <tr>
    <td><a href="https://github.com/michelson" target="_blank">Miguel Michelson Martinez ( michelson )</a></td>
    <td>Allowing HireFire to initialize in non-Ruby on Rails environments</td>
  </tr>
  <tr>
    <td><a href="https://github.com/nbibler" target="_blank">Nathaniel Bibler ( nbibler )</a></td>
    <td>Ensures that HireFire gracefully handles RestClient exceptions</td>
  </tr>
  <tr>
    <td><a href="https://github.com/samoli" target="_blank">Sam Oliver ( samoli )</a></td>
    <td>Adding the ability to specify a minimum amount of workers</td>
  </tr>
</table>


Want to contribute?
-------------------

- Fork/Clone the **develop** branch
- Write RSpec tests, and test against:
  - Ruby 1.9.2
  - Ruby 1.8.7
  - Ruby Enterprise Edition 1.8.7
- Try to keep the overall *structure / design* of the gem the same

I can't guarantee I'll pull every pull request. Also, I may accept your pull request and drastically change parts to improve readability/maintainability. Feel free to discuss about improvements, new functionality/features in the [issue log](https://github.com/meskyanichi/hirefire/issues) before contributing if you need/want more information.


Frequently Asked Questions
--------------------------

- **Question:** *Does it start workers immediately after a job gets queued?*
  - **Answer:** Yes, once a new job gets queued it'll immediately calculate the amount of workers that are required and hire them accordingly.

- **Question:** *Does it stop workers immediately when there are no jobs to be processed?*
  - **Answer:** Yes, every worker has been made self-aware to see this. Once there are no jobs to be processed, all workers will immediately be fired (shut down). *For example, if you have no jobs in the queue, and you start cranking up your Workers via Heroku's web ui, once the worker spawns and sees it has nothing to do, it'll immediately shut itself down.*

- **Question:** *How does this save me money?*
  - **Answer:** According to Heroku's documentation, Workers (same as Dynos), are prorated to the second. *For example, say that 10 jobs get queued and a worker is spawned to process them and takes about 1 minute to do so and then shuts itself down, theoretically you only pay $0.0008.*

- **Question:** *With Delayed Job you can set the :run_at to a time in the future.*
  - **Answer:** Unfortunately since we cannot spawn a monitoring process on the Heroku platform, HireFire will not hire workers until a job gets queued. This means that if you set the :run_at time a few minutes in the future, and these few minutes pass, the job will not be processed until a new job gets queued which triggers the chain of events. (Best to avoid using `run_at` with Delayed Job when using HireFire unless you have a mid-high traffic web application in which cause HireFire gets triggered enough times)

- **Question:** *If a job is set to run at a time in the future, will workers remain hired to wait for this job to be "processable"?*
  - **Answer:** No, because if you enqueue a job to run 3 hours from the time it was enqueued, you might have workers doing nothing the coming 3 hours. Best to avoid scheduling jobs to be processed in the future.

- **Question:** *Will it scale down workers from, for example, 5 to 4?*
  - **Answer:** No, I have consciously chosen not to do that for 2 reasons:
      1. There is no way to tell which worker is currently processing a job, so it might fire a worker that was busy, causing the job to be exit during the process.
      2. Does it really matter? Your jobs will be processed faster, and once the queue is completely empty, all workers will be fire anyway. (You could call this a feature! Since 5 jobs process faster than 4, but the cost remains the same cause it's all pro-rated to the second)

- **Question:** *Will running jobs concurrently (with multiple Worker) cost more?*
  - **Answer:** Actually, no. Since worker's are pro-rated to the second, the moment you hire 3 workers, it costs 3 times more, but it also processes 3 times faster. You could also let 1 worker process all the jobs rather than 3, but that means it'll still cost the same amount as when you hire 3 workers, since it takes 3 times longer to process.

- **Question:** *Can I process jobs faster with HireFire?*
  - **Answer:** When you run multiple jobs concurrently, you can speed up your processing dramatically. *Normally you wouldn't set the workers to 10 for example, but with HireFire you can tell it to Hire 10 workers when there are 50 jobs (would normally be overkill and cost you A LOT of money) but since (see Q/A above) Workers are pro-rated to the second, and HireFire immediately fires all workers once all the jobs in the queue have been processed, it makes no different whether you have a single worker processing 50 jobs, or 5 workers, or even 10 workers. It processes 10 times faster, but costs the same.*


Other potentially interesting gems
----------------------------------

* [Backup](https://github.com/meskyanichi/backup)
* [GitPusshuTen](https://github.com/meskyanichi/gitpusshuten)
* [Mongoid::Paperclip](https://github.com/meskyanichi/mongoid-paperclip)