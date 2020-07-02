module ToolingInvoker
  module Util
    class LogCollector

      def initialize
        @logs = []
      end

      def <<(external_command)
        @logs << external_command.report
      end

      def inspect
        @logs
      end

    end
  end

end
