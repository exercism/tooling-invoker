require 'open3'

module ToolingInvoker
  class ExecDocker
    include Mandate

    BLOCK_SIZE = 1024
    ONE_MEGABYTE_IN_BYTES = 1_024 * 1_024

    def initialize(job)
      @job = job
      @timeout_s = job.timeout_s.to_i
      @timeout_s = 20 unless @timeout_s > 0

      @container_label = "exercism-#{job.id}-#{SecureRandom.hex}"
      @output_limit = ONE_MEGABYTE_IN_BYTES
    end

    def call
      # We run the command in a thread and have another thread dedicated
      # to timeouts. This is in addition to the internal timeout command
      # that we use. We also want to look out for (and rescue)
      # various failed exit conditions (timeout, out of memory, etc)
      begin
        docker_thread = Thread.new do
          start_time = Time.now.to_f
          exec_command!
          puts "#{job.id}: Docker time: #{Time.now.to_f - start_time}"
        end

        # Run the command in a thread and timeout just
        # after the SIGKILL is sent inside ExternalCommand timeout.
        # Note whether it existed cleanly (success) or timed out
        success = docker_thread.join(timeout_s + 1.1)

        # If we get to this stage, and the thread didn't exit
        # clearly, it's still running and we need to stop it
        # We do this in two stages. First we call abort!, which
        # should clean up the service. Then we kill the actual thread.
        # This potentially orphans the child process. Getting here is
        # very unlikely as it means that the system level timeout has been
        # breached, but it just adds one tiny layer of protection.
        unless success
          abort!
          sleep(0.01)
          docker_thread.kill
        end
      rescue StandardError => e
        raise InvocationError.new(
          513,
          "The following error occurred: #{e.message}",
          data: to_h
        )
      end

      # Always explicity kill the containers in case they've timed-out
      # via out manual checks.
      kill_containers!

      # If we timed outvia the timeout command (exit status 124)
      # or we timed out here (success == false), # raise a timeout exception
      if exit_status == TIMEOUT_EXIT_STATUS || !success
        raise InvocationError.new(
          401, "Container timed out",
          data: {}
        )
      end

      if exit_status == EXCESSIVE_OUTPUT_EXIT_STATUS
        raise InvocationError.new(
          402, "Container overloaded IO",
          data: {}
        )
      end

      unless exit_status == 0
        raise InvocationError.new(
          513,
          "Container returned exit status of #{exit_status}",
          data: to_h
        )
      end

      to_h
    end

    private
    attr_reader :job, :container_label, :timeout_s, :output_limit,
                :exit_status, :stdout, :stderr, :pid

    def exec_command!
      captured_stdout = []
      captured_stderr = []

      stdin, stdout, stderr, wait_thr = Open3.popen3(docker_run_command)
      @pid = wait_thr[:pid]

      stdin.close_write

      begin
        while wait_thr.alive?
          break if stdout.closed?
          break if stderr.closed?

          files = IO.select([stdout, stderr])
          next unless files

          files[0].each do |f|
            if f.closed?
              @exit_status = EXCESSIVE_OUTPUT_EXIT_STATUS
              break
            end

            stream = f == stdout ? captured_stdout : captured_stderr
            begin
              stream << f.read_nonblock(BLOCK_SIZE)
            rescue IOError
              # Don't blow up if there is an error reading
              # the stream.
            end

            # If we haven't got too much output then continue for
            # another cycle. Our measure is the amount of blocks
            # we've collected over the total data we want.
            next unless output_limit.positive?
            next unless stream.size > (output_limit.to_f / BLOCK_SIZE)

            # If there is too much output, kill the process.
            abort!

            @exit_status = EXCESSIVE_OUTPUT_EXIT_STATUS
            break
          end
        end
      ensure
        stdout.close unless stdout.closed?
        stderr.close unless stderr.closed?

        @stdout = captured_stdout.join
        @stderr = captured_stderr.join
        @exit_status ||= wait_thr.value&.exitstatus

        File.write("#{job.output_dir}/stdout", @stdout)
        File.write("#{job.output_dir}/stderr", @stderr)
      end
    end

    def abort!
      Process.kill("KILL", pid)
    rescue StandardError
      # If the process has already gone, then don't
      # stress out. We'll already be raise a 401
      # downstream of here.
    end

    def kill_containers!
      # Always kill the container in case it's still running
      # TODO: Check if its running first
      cmd = [
        "docker container ls",
        "--filter='label=#{container_label}'",
        "-q"
      ].join(" ")
      stdout, = Open3.capture2(cmd)
      stdout.split.each do |container_id|
        system("docker kill #{container_id}")
      end
    end

    memoize
    def docker_run_command
      docker_cmd = [
        "docker container run",
        "-a stdout -a stderr", # Attach stdout and stderr
        "-v #{job.source_code_dir}:/mnt/exercism-iteration",
        "-l #{container_label}",
        "-m 3GB",
        "--stop-timeout 0", # Convert a SIGTERM to a SIGKILL instantly
        "--rm",
        "--network none",
        job.image,
        job.exercise, # TODO: These should be read from invocation_args
        "/mnt/exercism-iteration/",
        "/mnt/exercism-iteration/"
      ].join(" ")

      timeout_cmd = "/usr/bin/timeout -s SIGTERM -k 1 #{timeout_s} #{docker_cmd}"
      Exercism.env.development? ? docker_cmd : timeout_cmd
    end

    memoize
    def to_h
      {
        cmd: docker_run_command,
        exit_status: exit_status,
        stdout: fix_encoding(stdout),
        stderr: fix_encoding(stderr)
      }
    end

    def fix_encoding(text)
      return "" if text.nil?

      text.force_encoding("ISO-8859-1").encode("UTF-8")
    rescue StandardError => e
      puts e.message
      puts e.backtrace
      puts "--- failed to encode as UTF-8: #{e.message} ---"
      ""
    end
  end
end
