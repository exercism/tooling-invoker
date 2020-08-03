require 'test_helper'

module ToolingInvoker
  class InvocationErrorTest < Minitest::Test
    def test_everything_is_set_correctly
      error_code = 123
      msg = "an error message"
      exception = RuntimeError.new
      data = { foo: 'bar' }

      InvocationError.any_instance.expects(:puts).with("** #{error_code} | #{msg}")
      InvocationError.any_instance.expects(:puts).with("** #{exception.backtrace}")

      error = InvocationError.new(error_code, msg, exception: exception, data: data)
      expected = {
        worker_error_code: error_code,
        msg: msg,
        data: data
      }
      assert_equal expected, error.to_h
    end

    def test_defaults
      error_code = 123
      msg = "an error message"
      InvocationError.any_instance.expects(:puts).with("** #{error_code} | #{msg}")

      error = InvocationError.new(error_code, msg)
      expected = {
        worker_error_code: error_code,
        msg: msg,
        data: {}
      }
      assert_equal expected, error.to_h
    end

    def test_raises_properly
      assert_raises do
        raise InvocationError.new(123, "foobar")
      end
    end
  end
end
