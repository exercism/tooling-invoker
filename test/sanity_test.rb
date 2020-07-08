require 'test_helper'

module ToolingInvoker
  class SanityTest < Minitest::Test
    def test_sanity
      Timecop.freeze do
        ExternalCommand.any_instance.expects(:cmd).returns(
          "#{File.expand_path(File.dirname(__FILE__))}/../bin/mock_runc"
        ).at_least_once

        SyncS3.expects(:call).once

        id = SecureRandom.uuid
        hex1 = "some-hex"
        hex2 = "other-hex"
        SecureRandom.expects(:hex).twice.returns(hex1, hex2)

        expected = {
          exercise_slug: "bob", 
          iteration_dir: "tmp/foobar/ruby/releases/v1/runs/iteration_#{Time.now.to_i}-#{id}-#{hex1}", 
          rootfs_source: "tmp/foobar/ruby/releases/v1/rootfs", 
          invocation: {
            cmd: "bash -x -c 'ulimit -v 3000000; /opt/container_tools/runc --root root-state run test_run-other-hex-#{Time.now.to_i}'", 
            success: true, 
            stdout: "", 
            stderr: ""
          }, 
          result: {'happy' => 'people'}, 
          exit_status: 0, 
          msg_type: :response
        }

        actual = Invoker.new({
          "id" => id,
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

        assert_equal expected, actual
      end
    end
  end
end
