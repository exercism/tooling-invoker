require 'test_helper'

module ToolingInvoker
  class RuntimeEnvironmentTest < Minitest::Test
    def test_everything_is_set_correctly
      container_version = '123'
      track_slug = "ruby"
      job_id = "678"

      containers_dir = Configuration.containers_dir
      env = RuntimeEnvironment.new(container_version, track_slug, job_id)
      assert_equal "#{containers_dir}/ruby/releases/123", env.container_dir
      assert_equal "#{containers_dir}/ruby/releases/123/rootfs", env.rootfs_source
      assert_equal "#{containers_dir}/ruby/releases/123/jobs/#{job_id}", env.job_dir
      assert_equal "#{containers_dir}/ruby/releases/123/jobs/#{job_id}/code", env.source_code_dir
    end
  end
end
