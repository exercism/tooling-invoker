module ToolingInvoker
  class RuncWrapper

    attr_reader :logs

    def initialize(iteration_dir, configuration, execution_timeout: )
      @iteration_dir = iteration_dir
      @configuration = configuration
      @execution_timeout = execution_timeout || 5

      @binary_path = "/opt/container_tools/runc"
      #@binary_path = "#{File.expand_path(File.dirname(__FILE__))}/../../bin/mock_runc"
      @suppress_output = false
      @memory_limit = 3000000
      @logs = Util::LogCollector.new
    end

    def setup!
      File.write("#{iteration_dir}/config.json", configuration.to_json)
    end

    def run!
      container_id = "analyzer-#{Time.now.to_i}"

      actual_command = "#{binary_path} --root root-state run #{container_id}"
      run_cmd = Util::ExternalCommand.new(
        "bash -x -c 'ulimit -v #{memory_limit}; #{actual_command}'",
        timeout: execution_timeout,
        stdout_limit: 1024*1024,
        stderr_limit: 1024*1024
      )

      kill_cmd = Util::ExternalCommand.new("#{binary_path} --root root-state kill #{container_id} KILL")

      Dir.chdir(iteration_dir) do
        puts "HERE: #{logs}" + logs.class.to_s
        begin
          run_cmd.()
        rescue => e
          puts e.message
          puts "HERE"
          puts " --------- "
          raise
        ensure
          logs << run_cmd
          kill_cmd.()
        end
      end

      run_cmd
    end

    private
    attr_reader :binary_path, :suppress_output, :memory_limit, :execution_timeout, :iteration_dir, :configuration
  end
end

