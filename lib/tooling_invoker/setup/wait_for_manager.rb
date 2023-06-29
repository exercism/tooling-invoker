module ToolingInvoker
  module Setup
    class WaitForManager
      include Mandate

      def call
        dir = "/home/exercism"
        return unless Dir.exist?(dir)

        loop do
          if File.exist?("#{dir}/.tooling-manager-ready")
            Log.("Tooling Manager Ready. Continuing...")
            return
          else
            Log.("Waiting for tooling manager...")
            sleep(3)
          end
        end
      end
    end
  end
end
