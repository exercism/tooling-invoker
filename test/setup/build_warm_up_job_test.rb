require 'test_helper'

module ToolingInvoker
  module Setup
    class BuildWarmUpJobTest < Minitest::Test
      def setup
        super

        @repos_dir = Dir.mktmpdir
        @submission_dir = Dir.mktmpdir
        Exercism.config.stubs(:efs_repositories_mount_point).returns(@repos_dir)
      end

      def teardown
        super

        FileUtils.rm_rf(@repos_dir)
        FileUtils.rm_rf(@submission_dir)
      end

      def test_builds_a_job_for_hello_world_with_the_example_as_the_submission
        sha = create_repo!(
          "ruby",
          "bob" => exercise_files("bob.rb", ".meta/example.rb"),
          "hello-world" => exercise_files(
            "hello_world.rb", ".meta/example.rb",
            ".docs/instructions.md" => "Say hello",
            "hello_world.rb" => "STUB",
            "hello_world_test.rb" => "TESTS"
          )
        )

        job = BuildWarmUpJob.("ruby", @submission_dir, 120)

        assert_instance_of Jobs::TestRunnerJob, job
        assert_equal "ruby", job.language
        assert_equal "hello-world", job.exercise
        assert_equal 120, job.timeout_s
        assert_equal "EXAMPLE", File.read("#{@submission_dir}/hello_world.rb")
        assert_equal(
          {
            'submission_efs_root' => @submission_dir,
            'submission_filepaths' => ["hello_world.rb"],
            'exercise_git_repo' => "ruby",
            'exercise_git_sha' => sha,
            'exercise_git_dir' => "exercises/practice/hello-world",
            'exercise_filepaths' => %w[.meta/config.json .meta/example.rb hello_world_test.rb]
          },
          job.source.merge('exercise_filepaths' => job.source['exercise_filepaths'].sort)
        )
      end

      def test_uses_the_first_exercise_without_hello_world
        create_repo!(
          "fsharp",
          "bob" => exercise_files("Bob.fs", ".meta/Example.fs"),
          "acronym" => exercise_files("Acronym.fs", ".meta/Example.fs")
        )

        job = BuildWarmUpJob.("fsharp", @submission_dir, 120)

        assert_equal "acronym", job.exercise
        assert_equal "exercises/practice/acronym", job.source['exercise_git_dir']
      end

      def test_raises_without_a_repo
        assert_raises(Rugged::OSError) { BuildWarmUpJob.("missing", @submission_dir, 120) }
      end

      private
      # The files for an exercise with one solution file and its example.
      def exercise_files(solution, example, others = {})
        {
          ".meta/config.json" => { files: { solution: [solution], example: [example] } }.to_json,
          example => "EXAMPLE"
        }.merge(others)
      end

      # Creates a bare-bones track repo with the given practice exercises,
      # and returns the SHA of its only commit.
      def create_repo!(track, exercises)
        dir = "#{@repos_dir}/#{track}"
        exercises.each do |slug, files|
          files.each do |filepath, contents|
            path = "#{dir}/exercises/practice/#{slug}/#{filepath}"
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, contents)
          end
        end

        git = "git -C #{dir} -c user.name=test -c user.email=test@example.com"
        system("git init -q #{dir} && #{git} add . && #{git} commit -q -m init", exception: true)
        `git -C #{dir} rev-parse HEAD`.strip
      end
    end
  end
end
