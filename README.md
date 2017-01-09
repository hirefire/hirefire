## [HireFire.io] - Autoscaling for your Heroku dynos (Hosted Service)

**Note: This is not part of the open source variant**

[HireFire] is a hosted service for auto-scaling both web- and worker dynos. The service supports practically any worker library across all programming languages through an abstract interface. For worker dynos it does provide a handful of convenient macros for calculating queue depths for various worker libraries (like Delayed Job, Resque, Qu, QueueClassic, Sidekiq, Bunny, Que).

In addition to autoscaling worker dynos, the service also autoscales web dynos. To do this we leverage the Heroku Logplex, allowing your application (again, in any programming language) to scale based on response times, rpm or dyno (cpu) load.

Aside from scaling based on variables such as queue depths, response times, rpm and load, you can also configure time ranges to schedule scaling operations on every minute of the week to meet your demands. You can even do this exclusively (without auto-scaling) if you wish.

For a mere $10/mo per app we've got you covered.

Check out the [home page] and [docs] for more information.


---


## HireFire - Autoscaling for your Heroku workers (Open Source)

HireFire automatically scales your Heroku workers up- and down based on the size of queues. This library was specifically designed to work with [Delayed Job] and [Resque].

If you have a small application that only processes maybe 2 hours worth of background jobs a month, and you're letting the worker run 24/7, it'll end up costing you $25/mo (assuming Standard-1X size). Rather than letting said worker run 24/7, HireFire can scale it down when you don't have jobs to process, resulting in a bill of $0.07/mo, rather than $25/mo.

If you have a medium-to-large application, this can result in significant cost savings depending on the nature of your application. Additionally, auto-scaling also ensures that your application doesn't build up a large backlog of jobs. Another benefit is the ability to quickly spin up a lot of workers for a short period of time to process jobs faster (in parallel), without the additional cost because Heroku Dynos are pro-rated to the second. So, whether you run 1 worker for 1 hour, or 6 dynos for 10 minutes, the cost is the same, but your jobs are processed 6 times faster.


## Setting it up

In a Ruby on Rails environment, add the following:

**Rails.root/Gemfile**

    gem 'rails'
    # gem 'delayed_job' # uncomment this line if you use Delayed Job
    # gem 'resque'      # uncomment this line if you use Resque
    gem 'hirefire'

**(The order is important: "Delayed Job" / "Resque" > HireFire)**

Be sure to add the following Heroku environment variables so HireFire can manage your workers.

    heroku config:add HIREFIRE_EMAIL=<your_email> HIREFIRE_PASSWORD=<your_password>

These are the same email and password credentials you use to log in to the Heroku web interface to manage your workers. Note that you can also use your Heroku API token in the `HIREFIRE_PASSWORD` environment variable. You can get your Heroku API token from the Heroku UI or via the CLI with `heroku auth:token`.

That's all you need to do to get the default configuration set up. You'll probably want to tailor the auto-scaling configuration to your application's requirements. Create an initializer (or similar configuration file that's loaded at boot-time) and configure HireFire's scaling behavior like so:

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

Once done, you're ready to deploy to [Heroku].

What the above configuration does: It ensures that you never have more than 5 workers at a time (`config.max_workers = 5`). And then we define an array of hashes that represent our job:worker ratio. In the above example we are basically saying:

* Hire (= scale up) 1 worker if there are 1-14 queued jobs
* Hire (= scale up) 2 workers if there are 15-34 queued jobs
* Hire (= scale up) 3 workers if there are 35-59 queued jobs
* Hire (= scale up) 4 workers if there are 60-79 queued jobs
* Hire (= scale up) 5 workers if there are more than 80 queued jobs

Once all the jobs in the queue have been processed, it'll fire (= scale down) all the workers and start with a single worker the next time a new job gets queued. The next time the queue hits the 15 jobs mark, in which case the single worker isn't sufficient, it'll spin up the second worker, and at 35 jobs a third, etc.

*If you prefer a more functional way of defining your job:worker ratio, you could use the following notation style:*

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


## In a non-Ruby on Rails environment

Almost the same setup, except that you have to initialize HireFire yourself after [Delayed Job] or [Resque] is done loading.

    require 'delayed_job'
    # require 'delayed_job' # uncomment this line if you use Delayed Job
    # require 'resque'      # uncomment this line if you use Resque
    HireFire::Initializer.initialize!

**(Again, the order is important: "Delayed Job" / "Resque" > HireFire)**

If all goes well you should see a message similar to this when you boot your application:

    [HireFire] Delayed::Backend::ActiveRecord::Job detected!


## Worker / Mapper Support

HireFire currently works with the following worker and mapper libraries:

- [Delayed Job]
  - [ActiveRecord ORM]

- [Resque]
  - [Redis]


## Suggestions, Bugs, Requests, Questions

View the [issue tracker] and post them there.


## Contributors

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


## Frequently Asked Questions

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


## Author / License

Released under the [MIT License] by [Michael van Rooijen] of [HireFire].


[HireFire]: https://www.hirefire.io/
[HireFire.io]: https://www.hirefire.io/
[Heroku]: https://www.heroku.com
[Delayed Job]: https://github.com/collectiveidea/delayed_job
[ActiveRecord ORM]: https://github.com/rails/rails/tree/master/activerecord
[Resque]: https://github.com/resque/resque
[Redis]: https://github.com/redis/redis-rb
[issue tracker]: https://github.com/hirefire/hirefire/issues
[home page]: https://www.hirefire.io/
[docs]: http://support.hirefire.io/help/kb
[MIT License]: https://github.com/hirefire/hirefire/blob/readme/LICENSE
[Michael van Rooijen]: http://michael.vanrooijen.io
