module ToolingInvoker
  class SetupInputFiles
    include Mandate

    initialize_with :job

    def call
      FileUtils.cp_r(job.input_efs_dir, job.source_code_dir)
    end
  end
end
