module AppleEpf
  class DownloadProcessor

    def initialize(apple_filename_full, download_to)
      @apple_filename_full = apple_filename_full
      @download_to = download_to
    end

    def download_and_check
      raise 'should be implemented in subclass'
    end

    def get_file_md5
      begin
        curl = Curl::Easy.new("#{@apple_filename_full}.md5")
        curl.http_auth_types = :basic
        curl.username = AppleEpf.apple_id
        curl.password = AppleEpf.apple_password
        curl.perform
        @md5_checksum = curl.body_str.match(/.*=(.*)/)[1].strip
      rescue NoMethodError
        raise AppleEpf::Md5CompareError.new('Md5 of downloaded file is not the same as apple provide')
      end
    end
  end
end

require "apple_epf/download_processor/curb_download_processor"
require "apple_epf/download_processor/aria_download_processor"
