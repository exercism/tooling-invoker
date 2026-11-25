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
    # We do this once per boot. It must never stop the invoker from starting,
    # so every problem is logged and skipped, and we stop after
    # MAX_TOTAL_SECONDS. The marker file records each test runner as we
    # start it. If the invoker crashes and restarts during the pass, it
    # carries on with the test runners it hasn't started, and never retries
    # the one that was running, in case that runner caused the crash.
    class WarmUpTestRunners
      include Mandate

      MAX_TOTAL_SECONDS = 20 * 60

      # A first run can be very slow, so give it far longer than a job gets.
      RUN_TIMEOUT_SECONDS = 120

      MARKER_PATH = "/home/exercism/.test-runners-warmed-up".freeze
      BOOT_ID_PATH = "/proc/sys/kernel/random/boot_id".freeze

      def call
        return unless fleet_machine?

        # If several workers start at once, the first warms up and the
        # others wait here, then find nothing left to do.
        File.open("#{marker_path}.lock", File::RDWR | File::CREAT) do |lock|
          lock.flock(File::LOCK_EX)
          warm_up_remaining!
        end
      rescue StandardError => e
        Log.("Warm-up: failed, so skipping it: #{e.message}")
      end

      private
      def warm_up_remaining!
        remaining = languages - started_languages
        return if remaining.empty?

        started_at = Time.now.to_f
        Log.("Warm-up: running #{remaining.size} of #{languages.size} test runners")

        remaining.each do |language|
          if Time.now.to_f - started_at > MAX_TOTAL_SECONDS
            Log.("Warm-up: out of time, so skipping the remaining test runners")
            break
          end

          record_start!(language)
          warm_up!(language)
        end

        Log.("Warm-up: finished in #{(Time.now.to_f - started_at).round(1)}s")
      end

      # Only fleet machines have /home/exercism (see WaitForManager).
      def fleet_machine? = Dir.exist?(File.dirname(marker_path))

      # The marker holds this boot's ID, then one line for each test runner
      # started. If it's from an earlier boot, we start it again.
      def started_languages
        lines = File.exist?(marker_path) ? File.readlines(marker_path, chomp: true) : []
        return lines.drop(1) if lines.first == boot_id

        File.write(marker_path, "#{boot_id}\n")
        []
      end

      def record_start!(language) = File.write(marker_path, "#{language}\n", mode: "a")

      memoize
      def marker_path = MARKER_PATH

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
