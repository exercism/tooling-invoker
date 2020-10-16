module ToolingInvoker
  class RuncWrapper
    def initialize(job_dir, configuration, timeout: 5)
      @run_id = SecureRandom.hex

      @job_dir = job_dir
      @configuration = configuration
      @timeout = timeout.to_i
      @timeout = 5 unless @timeout > 0

      @binary_path = Configuration::RUNC_BINARY_PATH
      @suppress_output = false
      @memory_limit = 3_000_000
    end

    def run!
      # Firstly create the directory and setup the external
      # command. We don't expect anything to break where
      # but we have a generic rescue clause just in case
      begin
        File.write("#{job_dir}/config.json", configuration.to_json)

        cmd = ExternalCommand.new(
          "#{binary_path} --root root-state run #{run_id}",
          timeout: timeout
        )
      rescue StandardError => e
        raise InvocationError.new(
          513,
          "The following error occurred: #{e.message}",
          data: {}
        )
      end

      # Now we run the command. We want to look out for (and rescue)
      # various failed exit conditions (timeout, out of memory, etc)
      begin
        runc_thread = Thread.new do
          Dir.chdir(job_dir) do
            cmd.()
          end
        end

        # Run the command in a thread and timeout just
        # after the SIGKILL is sent inside ExternalCommand timeout.
        # Note whether it existed cleanly (success) or timed out
        success = runc_thread.join(timeout + 1.1)

        # If we get to this stage, and the thread didn't exit
        # clearly, it's still running and we need to stop it
        # We do this in two stages. First we call abort!, which
        # should clean up the service. Then we kill the actual thread.
        # This potentially orphans the child process. Getting here is
        # very unlikely as it means that the system level timeout has been
        # breached, but it just adds one tiny layer of protection.
        unless success
          cmd.abort!
          sleep(1)
          runc_thread.kill
        end
      rescue StandardError => e
        raise InvocationError.new(
          513,
          "The following error occurred: #{e.message}",
          data: cmd.to_h
        )
      end

      # Always kill the container in case it's still running
      # TODO: Check if its running first
      system("#{binary_path} --root root-state kill #{run_id} KILL")

      # Now get the output that we want to pass back
      output = cmd.to_h

      # If we timed outvia the timeout command (exit status 124)
      # or we timed out here (success == false), # raise a timeout exception
      if output[:exit_status] == TIMEOUT_EXIT_STATUS || !success
        raise InvocationError.new(
          401, "Container timed out",
          data: {}
        )
      end

      if output[:exit_status] == EXCESSIVE_OUTPUT_EXIT_STATUS
        raise InvocationError.new(
          402, "Container overloaded IO",
          data: {}
        )
      end

      unless output[:exit_status] == 0
        raise InvocationError.new(
          513,
          "Container returned exit status of #{output[:exit_status].inspect}",
          data: output
        )
      end

      output
    end

    private
    attr_reader :binary_path, :suppress_output, :memory_limit, :timeout, :job_dir, :configuration, :run_id
  end
end
