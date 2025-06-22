module ToolingInvoker
  class Worker
    class CheckCanary
      include Mandate

      def call
        return true if Exercism.env.development?

        job = Jobs::TestRunnerJob.new(
          "canary-#{SecureRandom.hex}",
          SecureRandom.hex,
          'ruby',
          'hello-world',
          CANARY_SOURCE,
          '1'
        )
        JobProcessor::ProcessJob.(job)

        return true if job.status == 200

        false
      end

      CANARY_SOURCE = {
        'submission_efs_root' => "/mnt/efs/tooling_jobs/canary",
        'submission_filepaths' => ["hello_world.rb"],
        'exercise_git_repo' => "ruby",
        'exercise_git_sha' => "508219b5722e3d5b678299159ceb396349cc0b25",
        'exercise_git_dir' => "exercises/practice/hello-world",
        'exercise_filepaths' => [
          "hello_world_test.rb"
        ]
      }.freeze
    end
  end
end
