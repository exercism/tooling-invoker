module ToolingInvoker
  class InvokeLocalShell
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      tool_dir = "#{config.containers_dir}/#{job.tool}"
      job_dir = "#{config.jobs_dir}/#{job.id}-#{SecureRandom.hex}"
      input_dir = "#{job_dir}/input"
      output_dir = "#{job_dir}/output"
      FileUtils.mkdir_p(input_dir)
      FileUtils.mkdir_p(output_dir)

      SyncS3.(job.s3_uri, input_dir)

      cmd = "/bin/sh bin/run.sh #{job.exercise} #{input_dir} #{output_dir}"
      Dir.chdir(tool_dir) do
        system(cmd)
      end

      job.stdout = ""
      job.stderr = ""
      job.output ? job.succeeded! : job.exceptioned!("No output")
    end

    private
    attr_reader :job

    def config
      ToolingInvoker.config
    end
  end
end
