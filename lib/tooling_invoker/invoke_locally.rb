module ToolingInvoker
  class InvokeLocally
    include Mandate

    def initialize(job)
      @job = job
    end

    def call
      tool_dir = "#{Configuration.containers_dir}/#{job.tooling_slug}"
      job_dir = "/tmp/tooling-jobs/#{job.id}"
      input_dir = "#{job_dir}/input"
      output_dir = "#{job_dir}/output"
      FileUtils.mkdir_p(input_dir)
      FileUtils.mkdir_p(output_dir)

      SyncS3.(job.s3_uri, input_dir)

      Dir.chdir(tool_dir) do
        `/bin/sh bin/run.sh #{job.exercise_slug} #{input_dir} #{output_dir}`
      end

      results = File.read("#{output_dir}/#{job.results_filepath}")

      {
        msg_type: :response,
        results: JSON.parse(results)
      }
    end

    private
    attr_reader :job
  end
end
