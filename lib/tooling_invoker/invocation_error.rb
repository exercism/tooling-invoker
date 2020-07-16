module ToolingInvoker
  class InvocationError < RuntimeError
    attr_reader :error_code, :msg, :cause, :data

    def initialize(error_code, msg, exception: nil, data: {})
      super("#{error_code}: #{msg}")

      @error_code = error_code
      @msg = msg
      @cause = exception
      @data = data

      log!
    end

    def to_h
      {
        worker_error_code: error_code,
        msg: msg,
        data: data
      }
    end

    def log!
      puts "** #{error_code} | #{msg}"
      puts "** #{cause.backtrace}" if cause
    end
  end
end
