class AppleEpf::AriaDownloadProcessor < AppleEpf::DownloadProcessor
  def download_and_check
    get_file_md5
    download
  end

  def download
    command = "cd #{File.dirname(@download_to)} && aria2c --continue --check-integrity=true --checksum=md5=#{@md5_checksum} -x#{AppleEpf.concurrent_downloads} -j#{AppleEpf.concurrent_downloads} -s#{AppleEpf.concurrent_downloads} --http-user=#{AppleEpf.apple_id} --http-passwd=#{AppleEpf.apple_password} -o #{File.basename(@download_to)} #{@apple_filename_full}"
    result = system(command)

    unless result
      raise AppleEpf::DownloaderError.new("Unable to download file. #{$?}")
    end
  end

end
