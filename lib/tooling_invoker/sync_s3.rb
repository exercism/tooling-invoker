module ToolingInvoker
  class SyncS3
    include Mandate

    initialize_with :s3_uri, :download_folder

    def call
      log "Syncing #{s3_uri} -> #{download_folder}"

      s3_client = ExercismConfig::SetupS3Client.()
      log "Created client"
      location_uri = URI(s3_uri)
      bucket = location_uri.host
      path = location_uri.path[1..-1]
      s3_download_path = "#{path}/"
      params = {
        bucket: bucket,
        prefix: s3_download_path
      }
      log "Listing #{s3_download_path}"
      resp = s3_client.list_objects(params)
      resp.contents.each do |item|
        key = item[:key]
        local_key = key.delete_prefix(s3_download_path)
        log "listing item #{local_key}"
        target = "#{download_folder}/#{local_key}"
        target_folder = File.dirname(target)
        log "mkdir #{target_folder}"
        FileUtils.mkdir_p target_folder
        log "get_object #{key} -> #{target}"
        s3_client.get_object(bucket: bucket,
                             key: key,
                             response_target: target)
        log "downloaded #{target}"
      end
    rescue StandardError => e
      log "ERROR in s3 sync #{e.message}"
      raise
    end

    def log(message)
      puts "** #{self.class} | #{message}"
    end
  end
end
