require 'test_helper'

module ToolingInvoker
  class RuntimeEnvironmentTest < Minitest::Test
    def test_everything_is_set_correctly
      Timecop.freeze do
        containers_dir = '/cnt'
        container_version = '123'
        track_slug = "ruby"
        iteration_id = "678"
        time = Time.now.to_i
        hex = 'a1b2c3'
        SecureRandom.expects(:hex).returns(hex)

        env = RuntimeEnvironment.new(containers_dir, container_version, track_slug, iteration_id)
        assert_equal '/cnt/ruby/releases/123', env.container_dir
        assert_equal "/cnt/ruby/releases/123/rootfs", env.rootfs_source
        assert_equal "/cnt/ruby/releases/123/runs/iteration_#{time}-678-a1b2c3", env.iteration_dir
        assert_equal "/cnt/ruby/releases/123/runs/iteration_#{time}-678-a1b2c3/code", env.source_code_dir
      end
    end
  end
end
