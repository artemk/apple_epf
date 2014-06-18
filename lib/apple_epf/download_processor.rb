require "net/http"
require "uri"
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
        uri = URI.parse("#{@apple_filename_full}.md5")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(AppleEpf.apple_id, AppleEpf.apple_password)
        response = http.request(request)
        @md5_checksum = response.body.match(/.*=(.*)/)[1].strip
      rescue NoMethodError
        raise AppleEpf::Md5CompareError.new('Md5 of downloaded file is not the same as apple provide')
      end
    end
  end
end

require "apple_epf/download_processor/net_http_download_processor"
#require "apple_epf/download_processor/curb_download_processor"
require "apple_epf/download_processor/aria_download_processor"
