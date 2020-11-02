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
      exit_status = Dir.chdir(tool_dir) do
        system(cmd)
      end

      job.context = {
        tool_dir: tool_dir,
        job_dir: job_dir,
        stdout: '',
        stderr: ''
      }
      job.invocation_data = {
        cmd: cmd,
        exit_status: exit_status
      }

      job.output = job.output_filepaths.each.with_object({}) do |output_filepath, hash|
        hash[output_filepath] = File.read("#{output_dir}/#{output_filepath}")
      end

      job.status = job.output ? 200 : 400
    end

    private
    attr_reader :job

    def config
      ToolingInvoker.config
    end
  end
end
