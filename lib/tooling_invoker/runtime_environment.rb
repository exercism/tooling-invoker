module ToolingInvoker
  class RuntimeEnvironment

    attr_reader :container_dir, :job_dir, :source_code_dir, :rootfs_source

    def initialize(container_version, tooling_slug, job_id)
      tool_dir = "#{Configuration.containers_dir}/#{tooling_slug}"

      if !container_version || container_version.empty?
        container_version = File.readlink("#{tool_dir}/current").split('/').last
      end

      @container_dir = "#{tool_dir}/releases/#{container_version}"
      @job_dir = "#{container_dir}/jobs/#{job_id}"
      @source_code_dir = "#{job_dir}/code"
      @rootfs_source = "#{container_dir}/rootfs"
    end

    def container_exists?
      Dir.exist?(container_dir)
    end
  end
end

