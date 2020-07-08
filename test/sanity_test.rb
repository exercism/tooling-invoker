require 'test_helper'

module ToolingInvoker
  class SanityTest < Minitest::Test
    def test_sanity
      Util::ExternalCommand.any_instance.expects(:cmd).returns(
        "#{File.expand_path(File.dirname(__FILE__))}/../bin/mock_runc"
      ).at_least_once

      SyncS3.expects(:call).once

      p Invoker.new({
        "id" => SecureRandom.uuid,
        "track_slug" => "ruby",
        "exercise_slug" => "bob",
        "s3_uri" => "s3://exercism-iterations/production/iterations/1182520",
        "execution_timeout" => 0,
        'context' => {
          "credentials" => {
            'access_key_id' => ENV["AWS_ACCESS_KEY_ID"],
            'secret_access_key' => ENV["AWS_SECRET_ACCESS_KEY"],
          }
        }
      }, 
      :test_run, 
      'tmp/foobar').invoke
    end
  end
end
