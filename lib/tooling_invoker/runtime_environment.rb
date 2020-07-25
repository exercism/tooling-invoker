module ToolingInvoker
  class RuntimeEnvironment

    attr_reader :container_dir, :job_dir, :source_code_dir, :rootfs_source

    def initialize(container_version, tool, job_id)
      tool_dir = "#{Configuration.containers_dir}/#{tool}"

      if !container_version || container_version.empty?
        container_version = File.readlink("#{tool_dir}/current").split('/').last
      end

      @container_dir = "#{tool_dir}/releases/#{container_version}"
      @job_dir = "#{Configuration.jobs_dir}/#{job_id}-#{SecureRandom.hex}"
      @source_code_dir = "#{job_dir}/code"
      @rootfs_source = "#{container_dir}/rootfs"
    end

    def container_exists?
      Dir.exist?(container_dir)
    end
  end
end

