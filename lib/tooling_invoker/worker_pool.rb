module ToolingInvoker
  class WorkerPool
    extend Mandate::InitializerInjector

    initialize_with :count

    def start!
      wait_until_manager_ready!

      $stdout.sync = true
      $stderr.sync = true

      # Setup docker network. If the network already
      # exists then this will be a noop. It takes about
      # 120ms to exec, so just do it on worker init
      system(
        "docker network create --internal internal",
        out: File::NULL, err: File::NULL
      )

      workers = (1..count).map { |idx| Worker.new(idx) }

      workers.each do |worker|
        fork { worker.start! }
      end

      %w[INT TERM].each do |sig|
        trap sig do
          p "Exit signal recieved"
          workers.each(&:exit!)
        end
      end

      Process.waitall
    end

    def wait_until_manager_ready!
      dir = "/home/exercism"
      return unless Dir.exist?(dir)

      loop do
        if File.exist?("#{dir}/.tooling-manager-ready")
          puts "Tooling Manager Ready. Continuing..."
          return
        else
          puts "Waiting for tooling manager..."
          sleep(3)
        end
      end
    end
  end
end
