module ToolingInvoker
  class WorkerPool
    extend Mandate::InitializerInjector

    initialize_with :count

    def start!
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
  end
end
