module ToolingInvoker
  module Setup
    # Builds a test runner job for a track's hello-world (see
    # WarmUpTestRunners), as the website would, from the track's repo at
    # HEAD. The exercise's example solution goes into submission_dir as the
    # student's files.
    class BuildWarmUpJob
      include Mandate

      initialize_with :language, :submission_dir, :timeout_s

      # The website leaves these out of the files it sends with each job.
      UNSENT_DIRS = %w[.docs/ .approaches/ .articles/].freeze

      def call
        solutions.each do |solution, example|
          FileUtils.mkdir_p(File.dirname("#{submission_dir}/#{solution}"))
          File.write("#{submission_dir}/#{solution}", read(example))
        end

        Jobs::TestRunnerJob.new(
          "warm-up-#{language}-#{SecureRandom.hex(4)}",
          SecureRandom.hex,
          language,
          exercise,
          {
            'submission_efs_root' => submission_dir,
            'submission_filepaths' => solutions.keys,
            'exercise_git_repo' => language,
            'exercise_git_sha' => commit.oid,
            'exercise_git_dir' => exercise_dir,
            'exercise_filepaths' => exercise_filepaths - solutions.keys
          },
          '1',
          timeout_s:
        )
      end

      private
      memoize
      def solutions
        files = JSON.parse(read(".meta/config.json"))["files"]
        ExampleSolutionFiles.(files["solution"], files["example"])
      end

      # Every track has hello-world, apart from a few. Those use their
      # first practice exercise instead.
      memoize
      def exercise
        exercises = tree("exercises/practice").each_tree.map { |entry| entry[:name] }
        exercises.include?("hello-world") ? "hello-world" : exercises.min
      end

      def exercise_filepaths
        filepaths = []
        tree(exercise_dir).walk_blobs(:preorder) { |root, entry| filepaths << "#{root}#{entry[:name]}" }
        filepaths.reject { |filepath| filepath.start_with?(*UNSENT_DIRS) }
      end

      def read(filepath) = tree("#{exercise_dir}/#{filepath}").content
      def tree(path) = repo.lookup(commit.tree.path(path)[:oid])
      def exercise_dir = "exercises/practice/#{exercise}"

      memoize
      def commit = repo.head.target

      memoize
      def repo = Rugged::Repository.new("#{Exercism.config.efs_repositories_mount_point}/#{language}")
    end
  end
end
