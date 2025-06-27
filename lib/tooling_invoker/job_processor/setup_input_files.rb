module ToolingInvoker
  module JobProcessor
    class SetupInputFiles
      include Mandate

      initialize_with :job

      def call
        copy_submission_files!
        copy_git_files!
      end

      def copy_submission_files!
        efs_path = job.source['submission_efs_root']

        job.source['submission_filepaths'].each do |filepath|
          destination = "#{job.source_code_dir}/#{filepath}"
          FileUtils.mkdir_p(destination.split("/").tap(&:pop).join("/"))
          FileUtils.cp("#{efs_path}/#{filepath}", destination)
        end
      end

      def copy_git_files!
        # Some jobs only use source files, not git file
        return unless job.source['exercise_git_repo']

        job.source['exercise_filepaths'].each do |filepath|
          contents = file_contents(filepath)

          destination = "#{job.source_code_dir}/#{filepath}"
          FileUtils.mkdir_p(destination.split("/").tap(&:pop).join("/"))
          File.write(destination, contents)
        end
      end

      memoize
      def repo = Rugged::Repository.new(repo_dir)

      memoize
      def commit = repo.lookup(job.source['exercise_git_sha'])

      memoize
      def repo_dir = "#{Exercism.config.efs_repositories_mount_point}/#{job.source['exercise_git_repo']}"

      def file_contents(filepath)
        cache_key = Exercism::ToolingJob.git_cache_key(
          job.source['exercism_git_repo'],
          job.source['exercise_git_sha'],
          job.source['exercise_git_dir'],
          filepath
        )

        # Look up the blob in redis
        # If we have the blob in the cache, reset the TTL
        # to give it some value and then return it.
        blob = redis_cache_client.get(cache_key)
        if blob && !blob.empty?
          redis_cache_client.expire(cache_key, EXPIRE_PERIOD)
          return blob
        end

        file_contents_from_efs(filepath).tap do |blob|
          redis_cache_client.set(cache_key, blob, ex: EXPIRE_PERIOD)
        end
      rescue StandardError
        # Gracefully handle not having a cache
        Log.("Unable to access cache!", job:)
        file_contents_from_efs(filepath)
      end

      def file_contents_from_efs(filepath)
        entry = commit.tree.path("#{job.source['exercise_git_dir']}/#{filepath}")
        repo.lookup(entry[:oid])&.text
      end

      memoize
      def redis_cache_client = Exercism.redis_git_cache_client

      EXPIRE_PERIOD = 60 * 60 * 12 # 12 hours
    end
  end
end
