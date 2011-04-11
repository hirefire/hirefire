# encoding: utf-8

module ::Resque
  class Job
    def perform
      job = payload_class
      job_args = args || []
      job_was_performed = false

      before_hooks  = Plugin.before_hooks(job)
      around_hooks  = Plugin.around_hooks(job)
      after_hooks   = Plugin.after_hooks(job)
      failure_hooks = Plugin.failure_hooks(job)

      begin
        # Execute before_perform hook. Abort the job gracefully if
        # Resque::DontPerform is raised.
        begin
          before_hooks.each do |hook|
            job.send(hook, *job_args)
          end
        rescue DontPerform
          return false
        end

        # Execute the job. Do it in an around_perform hook if available.
        if around_hooks.empty?
          job.perform(*job_args)
          job_was_performed = true
        else
          # We want to nest all around_perform plugins, with the last one
          # finally calling perform
          stack = around_hooks.reverse.inject(nil) do |last_hook, hook|
            if last_hook
              lambda do
                job.send(hook, *job_args) { last_hook.call }
              end
            else
              lambda do
                job.send(hook, *job_args) do
                  result = job.perform(*job_args)
                  job_was_performed = true
                  result
                end
              end
            end
          end
          stack.call
        end

        ##
        # HireFire Hook
        # After a job finishes processing, we invoke the #fire
        # method on the environment object which will check to see whether
        # we can fire all the hired workers
        ::Resque::Job.environment.fire

        # Execute after_perform hook
        after_hooks.each do |hook|
          job.send(hook, *job_args)
        end

        # Return true if the job was performed
        return job_was_performed

      # If an exception occurs during the job execution, look for an
      # on_failure hook then re-raise.
      rescue Object => e
        failure_hooks.each { |hook| job.send(hook, e, *job_args) }
        raise e
      end
    end

  end
end
