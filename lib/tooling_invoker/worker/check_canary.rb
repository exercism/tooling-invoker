module ToolingInvoker
  class Worker
    class CheckCanary
      include Mandate

      def call
        job = Jobs::TestRunnerJob.new(
          "canary-#{SecureRandom.hex}",
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
        'submission_efs_root' => "cb5a174a13494e3a8aa556bc5097b7e2",
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
