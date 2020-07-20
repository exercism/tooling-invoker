module ToolingInvoker
  class RuntimeEnvironment

    attr_reader :container_dir, :job_dir, :source_code_dir, :rootfs_source

    def initialize(container_version, language_slug, job_id)
      track_containers_dir = "#{Configuration.containers_dir}/#{language_slug}"

      if !container_version || container_version.empty?
        container_version = File.readlink("#{track_containers_dir}/current").split('/').last
      end

      @container_dir = "#{track_containers_dir}/releases/#{container_version}"
      @job_dir = "#{container_dir}/jobs/#{job_id}"
      @source_code_dir = "#{job_dir}/code"
      @rootfs_source = "#{container_dir}/rootfs"
    end

    def container_exists?
      Dir.exist?(container_dir)
    end
  end
end

