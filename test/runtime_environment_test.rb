require 'test_helper'

module ToolingInvoker
  class RuntimeEnvironmentTest < Minitest::Test
    def test_everything_is_set_correctly
      container_version = '123'
      track_slug = "ruby"
      job_id = "678"
      hex = SecureRandom.hex
      SecureRandom.expects(:hex).returns(hex)

      containers_dir = Configuration.containers_dir
      jobs_dir = Configuration.jobs_dir
      env = RuntimeEnvironment.new(container_version, track_slug, job_id)
      assert_equal "#{containers_dir}/ruby/releases/123", env.container_dir
      assert_equal "#{containers_dir}/ruby/releases/123/rootfs", env.rootfs_source
      assert_equal "#{jobs_dir}/#{job_id}-#{hex}", env.job_dir
      assert_equal "#{jobs_dir}/#{job_id}-#{hex}/code", env.source_code_dir
    end
  end
end
