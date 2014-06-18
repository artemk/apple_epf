class AppleEpf::NetHTTPDownloadProcessor < AppleEpf::DownloadProcessor
  def download_and_check
    @download_retry = 0
    get_file_md5
    download
    compare_md5_checksum
  end

  def compare_md5_checksum
    if Digest::MD5.file(@download_to).hexdigest != @md5_checksum
      raise AppleEpf::Md5CompareError.new('Md5 of downloaded file is not the same as apple provide')
    end
  end

  private
  def download
    opt = {
      :init_pause => 0.1,    #start by waiting this long each time
                             # it's deliberately long so we can see 
                             # what a full buffer looks like
      :learn_period => 0.3,  #keep the initial pause for at least this many seconds
      :drop_factor => 1.5,   #fast reducing factor to find roughly optimized pause time
      :adjust => 1.05        #during the normal period, adjust up or down by this factor
    }

    pause = opt[:init_pause]
    learn = 1 + (opt[:learn_period]/pause).to_i
    drop_period = true
    delta = 0
    max_delta = 0
    last_pos = 0
    File.open(@download_to, 'wb') do |f|
      begin
        uri = URI.parse(@apple_filename_full)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(AppleEpf.apple_id, AppleEpf.apple_password)
        http.request(request) do |res|
          res.read_body do |seg|
            f << seg
            delta = f.pos - last_pos
            if delta > max_delta then max_delta = delta end
            if learn <= 0 then
              learn -= 1
            elsif delta == max_delta then
              if drop_period then
                pause /= opt[:drop_factor]
              else
                pause /= opt[:adjust]
              end
            elsif delta < max_delta then
              drop_period = false
              pause *= opt[:adjust]
            end
            sleep(pause)
          end
        end
      rescue Exception => e
        if @download_retry < AppleEpf.download_retry_count
          @download_retry += 1
          download
        else
          raise e
        end
      end
    end
  end
end
