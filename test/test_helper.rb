ENV["EXERCISM_ENV"] = "test"

# This must happen above the env require below
if ENV["CAPTURE_CODE_COVERAGE"]
  require 'simplecov'
  SimpleCov.start
end

gem "minitest"
require "minitest/autorun"
require "minitest/pride"
require "minitest/mock"
require "mocha/minitest"
require "timecop"

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require "tooling_invoker"

# The tests get very noisy if killed threads
# are allowed to report, so shut it up
Thread.report_on_exception = false

Mocha.configure do |c|
  # c.stubbing_method_unnecessarily = :prevent
  c.stubbing_non_existent_method = :prevent
  c.stubbing_method_on_nil = :prevent
  # c.stubbing_non_public_method = :prevent
end

# Silence the noise. Comment this to see exception
# messages and other things that are printed during tests.
module Kernel
  def puts(*args); end
end

module Minitest
  class Test
    def config
      ToolingInvoker.config
    end

    def upload_to_s3(bucket, key, body) # rubocop:disable Naming/VariableNumber
      Exercism.s3_client.put_object(
        bucket:,
        key:,
        body:,
        acl: 'private'
      )
    end

    def download_s3_file(bucket, key)
      Exercism.s3_client.get_object(
        bucket:,
        key:
      ).body.read
    end
  end
end
