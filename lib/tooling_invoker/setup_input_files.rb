module ToolingInvoker
  class SetupInputFiles
    include Mandate

    initialize_with :job

    def call
      copy_submission_files!
      copy_git_files!
    end

    def copy_submission_files!
      efs_path = "#{Exercism.config.efs_submissions_mount_point}/#{job.source['submission_efs_root']}"

      job.source['submission_filepaths'].each do |filepath|
        destination = "#{job.source_code_dir}/#{filepath}"
        FileUtils.mkdir_p(destination.split("/").tap(&:pop).join("/"))
        FileUtils.cp("#{efs_path}/#{filepath}", destination)
      end
    end

    def copy_git_files!
      # Some jobs only use source files, not git file
      return unless job.source['exercise_git_repo']

      repo_dir = "#{Exercism.config.efs_repositories_mount_point}/#{job.source['exercise_git_repo']}"
      repo = Rugged::Repository.new(repo_dir)
      commit = repo.lookup(job.source['exercise_git_sha'])

      job.source['exercise_filepaths'].each do |filepath|
        entry = commit.tree.path("#{job.source['exercise_git_dir']}/#{filepath}")
        blob = repo.lookup(entry[:oid])

        destination = "#{job.source_code_dir}/#{filepath}"
        FileUtils.mkdir_p(destination.split("/").tap(&:pop).join("/"))
        File.write(destination, blob.text)
      end
    end
  end
end
