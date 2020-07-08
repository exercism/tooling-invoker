module ToolingInvoker
  class InvocationError < RuntimeError
    attr_reader :error_code, :msg, :exception, :data

    def initialize(error_code, msg, exception: nil, data: {})
      @error_code = error_code
      @msg = msg
      @exception = exception
      @data = data

      log!
    end

    def to_hash
      {
        worker_error_code: error_code,
        msg: msg,
        data: data
      }
    end

    def log!
      puts "** #{error_code} | #{msg}"
      puts "** #{exception.backtrace}" if exception
    end
  end
end
