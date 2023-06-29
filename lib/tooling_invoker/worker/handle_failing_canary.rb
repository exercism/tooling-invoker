module ToolingInvoker
  class Worker
    class HandleFailingCanary
      include Mandate

      def call
        # We run this 10 times with increasing backoffs.
        # The whole process should take ~8.5mins
        BACKOFFS.each.with_index do |backoff, idx|
          puts "Checking Canary (#{idx + 1}/#{MAX_ATTEMPTS})..."

          # If things return, we can happily leave this
          return if CheckCanary.() # rubocop:disable Lint/NonLocalExitFromIterator

          # Otherwise back off until the next check
          sleep(backoff)
        end

        # Everything's gone to hell. Tell the machine to shut down
        # And then raise an exception.
        `sudo shutdown now`
        raise ExitWorkerError
      end

      BACKOFFS = [1, 2, 4, 8, 16, 32, 64, 128, 256].freeze
      MAX_ATTEMPTS = BACKOFFS.size
    end
  end
end
