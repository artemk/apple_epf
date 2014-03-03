class AppleEpf::CurbDownloadProcessor < AppleEpf::DownloadProcessor
  def download_and_check
    @download_retry = 0
    get_file_md5
    download
    compare_md5_checksum
    @download_to
  end

  def compare_md5_checksum
    if Digest::MD5.file(@download_to).hexdigest != @md5_checksum
      raise AppleEpf::Md5CompareError.new('Md5 of downloaded file is not the same as apple provide')
    end
  end

  private
  def download
    begin
      curl = Curl::Easy.new(@apple_filename_full)

      # Authentication
      curl.http_auth_types = :basic
      curl.username = AppleEpf.apple_id
      curl.password = AppleEpf.apple_password

      File.open(@download_to, 'wb') do |f|
        curl.on_body { |data|
          f << data;
          data.size
        }
        curl.perform
      end
    rescue Curl::Err::PartialFileError => ex
      if @download_retry < AppleEpf.download_retry_count
        @download_retry += 1

        logger_info "Curl::Err::PartialFileError happened..."
        logger_info "Restarting download"
        download
      else
        raise AppleEpf::CurlError.new("Unable to download file.")
      end
    end
  end

end
