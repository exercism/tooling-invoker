require 'open3'

module ToolingInvoker
  class ExternalCommand

    BLOCK_SIZE = 1024

    def initialize(cmd_string, timeout: nil, output_limit: -1, suppress_output: false)
      @cmd_string = cmd_string
      @output_limit = output_limit
      @suppress_output = suppress_output

      if timeout && timeout > 0
        @cmd = "/usr/bin/timeout -s 9 -k #{timeout + 1} #{timeout} #{cmd_string}"
      else
        @cmd = cmd_string
      end
    end

    def call
      invoke_process

      puts "status: #{status}" unless suppress_output
      puts "stdout: #{stdout}" unless suppress_output
      puts "stderr: #{stderr}" unless suppress_output

      raise "Failed #{cmd_string}" unless status.success?
    end

    def report
      {
        cmd: cmd_string,
        success: success?,
        stdout: fix_encoding(stdout),
        stderr: fix_encoding(stderr)
      }
    end

    def exit_status
      status.exitstatus
    end

    private
    attr_accessor :cmd_string, :output_limit, :status, :stdout, :stderr, :suppress_output

    def invoke_process
      captured_stdout = []
      captured_stderr = []
      killed = false

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        pid = wait_thr.pid
        stdin.close_write

        begin
          until stdout.eof || stderr.eof || killed do
            files = IO.select([stdout, stderr])
            files[0].each do |f|
              begin
                stream = f == stdout ? captured_stdout : captured_stderr

                stream << f.read_nonblock(BLOCK_SIZE)
                if stdout_limit > 0 && stream.size > output_limit
                  Process.kill("KILL", wait_thr.pid)
                  killed = true
                end
              rescue EOFError => e
              end
            end if files
          end
        rescue IOError => e
          puts "IOError: #{e}"
        ensure
          @stdout = captured_stdout.join
          @stderr = captured_stderr.join
          @status = wait_thr.value
        end
      end
    end

    def success?
      status && status.success?
    end

    def fix_encoding(text)
      return nil if text.nil?
      text.force_encoding("ISO-8859-1").encode("UTF-8")
    rescue => e
      puts e.message
      puts e.backtrace
      "--- failed to encode as UTF-8: #{e.message} ---"
    end
  end
end
