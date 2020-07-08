module ToolingInvoker
  class RuncWrapper

    def initialize(job_id, iteration_dir, configuration, execution_timeout: nil)
      @job_id = job_id
      @iteration_dir = iteration_dir
      @configuration = configuration
      @execution_timeout = execution_timeout || 5

      @binary_path = "/opt/container_tools/runc"
      #@binary_path = "#{File.expand_path(File.dirname(__FILE__))}/../../bin/mock_runc"
      @suppress_output = false
      @memory_limit = 3000000
    end

    def setup!
      File.write("#{iteration_dir}/config.json", configuration.to_json)
    end

    def run!
      actual_command = "#{binary_path} --root root-state run #{job_id}"
      run_cmd = ExternalCommand.new(
        "bash -x -c 'ulimit -v #{memory_limit}; #{actual_command}'",
        timeout: execution_timeout,
        output_limit: 1024*1024
      )

      kill_cmd = ExternalCommand.new("#{binary_path} --root root-state kill #{job_id} KILL")

      Dir.chdir(iteration_dir) do
        begin
          run_cmd.()
        rescue => e
          puts e.message
          puts "HERE"
          puts " --------- "
          raise
        ensure
          kill_cmd.()
        end
      end

      run_cmd
    end

    private
    attr_reader :binary_path, :suppress_output, :memory_limit, :execution_timeout, :iteration_dir, :configuration
    attr_reader :job_id
  end
end

