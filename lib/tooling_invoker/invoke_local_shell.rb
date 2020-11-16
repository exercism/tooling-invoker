module ToolingInvoker
  class InvokeLocalShell
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      tool_dir = "#{config.containers_dir}/#{job.tool}"

      FileUtils.mkdir_p(job.source_code_dir)

      # TODO: When docker moves to seperate dirs, move this too.
      # FileUtils.mkdir_p(output_dir)

      SetupInputFiles.(job)

      cmd = "/bin/sh bin/run.sh #{job.exercise} #{job.source_code_dir} #{job.source_code_dir}"
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
