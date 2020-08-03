require 'open3'

module ToolingInvoker
  class ExternalCommand
    BLOCK_SIZE = 1024

    def initialize(raw_cmd, timeout: 0, output_limit: -1, suppress_output: false)
      @raw_cmd = raw_cmd
      @output_limit = output_limit
      @suppress_output = suppress_output

      @cmd = "/usr/bin/timeout -s 15 -k #{timeout + 1} #{timeout} #{raw_cmd}"
    end

    def call
      invoke_process
    end

    def to_h
      {
        cmd: raw_cmd,
        exit_status: status&.exitstatus,
        stdout: fix_encoding(stdout),
        stderr: fix_encoding(stderr)
      }
    end

    private
    attr_accessor :cmd, :raw_cmd, :output_limit, :status, :stdout, :stderr, :suppress_output

    def invoke_process
      captured_stdout = []
      captured_stderr = []
      killed = false

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stdin.close_write

        begin
          while wait_thr.alive?
            break if killed
            break unless wait_thr.alive?
            break if stdout.closed?
            break if stderr.closed?

            files = IO.select([stdout, stderr])
            next unless files

            files[0].each do |f|
              if f.closed?
                killed = true
                break
              end

              stream = f == stdout ? captured_stdout : captured_stderr
              begin
                stream << f.read_nonblock(BLOCK_SIZE)
              rescue IOError
              end

              # If we haven't got too much output then continue for
              # another cycle.
              next unless output_limit.positive? && stream.size > output_limit

              # If there is too much output, kill the process
              p "Killing the process"
              Process.kill("KILL", wait_thr.pid)
              killed = true
              break
            end
          end
        rescue IOError => e
          puts "IOError: #{e}"
        ensure
          stdout.close unless stdout.closed?
          stderr.close unless stderr.closed?

          @stdout = captured_stdout.join
          @stderr = captured_stderr.join
          @status = wait_thr.value
        end
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
  end
end
