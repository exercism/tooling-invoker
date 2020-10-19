require 'open3'

module ToolingInvoker
  class ExternalCommand
    BLOCK_SIZE = 1024
    ONE_MEGABYTE_IN_BYTES = 1_024 * 1_024
    THREE_GIGABYTES_IN_KILOBYTES = 3_000_000

    def initialize(cmd,
                   output_limit: ONE_MEGABYTE_IN_BYTES,
                   memory_limit: THREE_GIGABYTES_IN_KILOBYTES,
                   timeout:,
                   suppress_output: false)
      @cmd = cmd
      @timeout = timeout
      @output_limit = output_limit
      @memory_limit = memory_limit
      @suppress_output = suppress_output
      @killed_for_excessive_output = false
    end

    def call
      invoke_process
    end

    def to_h
      exit_status = if killed_for_excessive_output
                      EXCESSIVE_OUTPUT_EXIT_STATUS
                    else
                      status&.exitstatus
                    end

      {
        cmd: cmd,
        exit_status: exit_status,
        stdout: fix_encoding(stdout),
        stderr: fix_encoding(stderr)
      }
    end

    def abort!
      Process.kill("KILL", @pid)
    rescue StandardError
      # If the process has already gone, then don't
      # stress out. We'll already be raise a 401
      # downstream of here.
    end

    private
    attr_reader :cmd, :timeout, :output_limit, :memory_limit, :suppress_output,
                :status, :stdout, :stderr, :pid, :killed_for_excessive_output

    def invoke_process
      captured_stdout = []
      captured_stderr = []

      stdin, stdout, stderr, wait_thr = Open3.popen3(wrapped_cmd)
      @pid = wait_thr[:pid]

      stdin.close_write

      begin
        while wait_thr.alive?
          break if killed_for_excessive_output
          break unless wait_thr.alive?
          break if stdout.closed?
          break if stderr.closed?

          files = IO.select([stdout, stderr])
          next unless files

          files[0].each do |f|
            if f.closed?
              @killed_for_excessive_output = true
              break
            end

            stream = f == stdout ? captured_stdout : captured_stderr
            begin
              stream << f.read_nonblock(BLOCK_SIZE)
            rescue IOError
            end

            # If we haven't got too much output then continue for
            # another cycle. Our measure is the amount of blocks
            # we've collected over the total data we want.
            # p stream
            next unless output_limit.positive?
            next unless stream.size > (output_limit.to_f / BLOCK_SIZE)

            # If there is too much output, kill the process
            Process.kill("KILL", @pid)
            @killed_for_excessive_output = true
            break
          end
        end
      # rescue IOError => e
      #  puts "IOError: #{e}"
      ensure
        stdout.close unless stdout.closed?
        stderr.close unless stderr.closed?

        @stdout = captured_stdout.join
        @stderr = captured_stderr.join
        @status = wait_thr.value
      end
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

    # We wrap this command in two levels.
    # The first is a timeout which runs SIGTERM after timeout seconds and
    # SIGKILL after timeout seconds + 1.
    # We then use ulimit to limit the amount of memeory consumed.
    def wrapped_cmd
      "/usr/bin/timeout -s SIGTERM -k 1 #{timeout} bash -x -c 'ulimit -v #{memory_limit}; #{cmd}'"
    end
  end
end
