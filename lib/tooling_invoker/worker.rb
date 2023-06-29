module ToolingInvoker
  class Worker
    extend Mandate::InitializerInjector

    class ExitWorkerError < StandardError
    end

    initialize_with :worker_idx

    def exit!
      @should_exit = true
    end

    def start!
      Log.("Worker #{worker_idx}: Starting")

      counter = 0

      loop do
        if should_exit?
          Log.("Worker #{worker_idx}: Exiting")
          break
        end

        if counter > 100
          counter = 0
          Log.("Worker #{worker_idx}: Alive at #{Time.now}")
        else
          counter += 1
        end

        job = Worker::RetrieveJob.()

        if job
          Log.("Starting job", job:)
          start_time = Time.now.to_f
          Worker::HandleJob.(job)
          Log.("Total time: #{Time.now.to_f - start_time}", job:)
        else
          sleep(ToolingInvoker.config.job_polling_delay)
        end
      rescue ExitWorkerError => e
        exit!
      rescue StandardError => e
        Log.("Top level error")
        Log.(e.message)
        Log.(e.backtrace)

        sleep(ToolingInvoker.config.job_polling_delay)
      end
    end

    private
    def should_exit?
      @should_exit
    end

    def config
      ToolingInvoker.config
    end
  end
end
