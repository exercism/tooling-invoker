require 'tmpdir'

module ToolingInvoker
  module Setup
    # Runs each test runner on this machine once, before we take any jobs.
    #
    # On a new machine, none of a runner's files have been read yet, so its
    # first job is slow (C# and JavaScript take over 20s) and can time out
    # for a student. Once a runner has run once, it stays fast. So we run
    # each one on its track's hello-world, with the exercise's example
    # solution as the submission, to take that hit before students do.
    #
    # We do this once per boot, as a restarted invoker has nothing to warm
    # up. It must never stop the invoker from starting, so we mark it done
    # before we start (so a crash part way through isn't repeated), every
    # problem is logged and skipped, and we stop after MAX_TOTAL_SECONDS.
    class WarmUpTestRunners
      include Mandate

      MAX_TOTAL_SECONDS = 20 * 60

      # A first run can be very slow, so give it far longer than a job gets.
      RUN_TIMEOUT_SECONDS = 120

      MARKER_PATH = "/home/exercism/.test-runners-warmed-up".freeze
      BOOT_ID_PATH = "/proc/sys/kernel/random/boot_id".freeze

      def call
        return unless claim_boot!

        started_at = Time.now.to_f
        Log.("Warm-up: running #{languages.size} test runners")

        languages.each do |language|
          if Time.now.to_f - started_at > MAX_TOTAL_SECONDS
            Log.("Warm-up: out of time, so skipping the remaining test runners")
            break
          end

          warm_up!(language)
        end

        Log.("Warm-up: finished in #{(Time.now.to_f - started_at).round(1)}s")
      rescue StandardError => e
        Log.("Warm-up: failed, so skipping it: #{e.message}")
      end

      private
      # Returns true, and records that this boot has been warmed up, if it
      # hasn't been yet. Only fleet machines have /home/exercism (see
      # WaitForManager), so this is false everywhere else.
      def claim_boot!
        return false unless Dir.exist?(File.dirname(MARKER_PATH))
        return false if File.exist?(MARKER_PATH) && File.read(MARKER_PATH) == boot_id

        File.write(MARKER_PATH, boot_id)
        true
      end

      memoize
      def boot_id = File.read(BOOT_ID_PATH).strip

      # The tooling manager pulls the images for this machine's tools before
      # we start, so the test runners on this machine are those images.
      memoize
      def languages
        prefix = "#{config.image_registry}/"
        suffix = "-test-runner"

        `docker image ls --filter 'reference=#{prefix}*#{suffix}:#{config.image_tag}' --format '{{.Repository}}'`.
          split.map { |repository| repository.delete_prefix(prefix).delete_suffix(suffix) }.
          uniq.sort
      end

      def warm_up!(language)
        Dir.mktmpdir do |submission_dir|
          job = BuildWarmUpJob.(language, submission_dir, RUN_TIMEOUT_SECONDS)
          JobProcessor::ProcessJob.(job)

          Log.("Warm-up: #{language} ran #{job.exercise} in #{job.duration.to_f.round(1)}s " \
               "(status #{job.status}, tests #{tests_status(job)})")
        ensure
          FileUtils.rm_rf(job.dir) if job
        end
      rescue StandardError => e
        Log.("Warm-up: skipped #{language} after an error: #{e.message}")
      end

      # The example should pass, so anything else is worth a look, but it
      # still means the runner's files have been read, which is what we need.
      def tests_status(job)
        JSON.parse(job.output["results.json"])["status"]
      rescue StandardError
        "wrote no results"
      end

      def config = ToolingInvoker.config
    end
  end
end
