require 'net/http'
require 'date'
require 'curb'
require 'digest/md5'

module AppleEpf
  class Downloader
    include AppleEpf::Logging
    ITUNES_FLAT_FEED_URL = 'https://feeds.itunes.apple.com/feeds/epf/v3/full'.freeze

    attr_accessor :type, :filename, :filedate

    attr_reader :download_to, :apple_filename_full
    attr_writer :dirpath
    def initialize(type, filename, filedate)
      @type = type
      @filename = filename #itunes, popularity, match, pricing
      @filedate = filedate
    end

    def download
      _prepare_folders
      get_filename_by_date_and_type

      @apple_filename_full = apple_filename_full_url(@apple_filename_full_path)
      @download_to = File.join(dirpath, File.basename(@apple_filename_full))

      logger_info "Download file: #{@apple_filename_full}"
      logger_info "Download to: #{@download_to}"

      @download_retry = 0
      start_download
      download_and_compare_md5_checksum
      @download_to
    end

    def dirpath
      File.join((@dirpath || AppleEpf.extract_dir), @type)
    end

    #TODO combine with start_download
    def download_and_compare_md5_checksum
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

      if Digest::MD5.file(@download_to).hexdigest != @md5_checksum
        raise AppleEpf::Md5CompareError.new('Md5 of downloaded file is not the same as apple provide')
      end

      @md5_checksum
    end

    def get_filename_by_date_and_type
      #today = DateTime.now
      path = ""
      case @type
        when "full"
          path = "#{main_dir_date}/#{@filename}#{main_dir_date}.tbz"

        when "incremental"
          date_of_file = date_to_epf_format(@filedate)
          path = "#{main_dir_date}/incremental/#{date_of_file}/#{@filename}#{date_of_file}.tbz"

        when "file"
          #TODO: FIX THIS
          # date = date_to_epf_format( @filedate, check_if_in_previous_week, check_if_in_thursday )
          # path = "#{file}#{date}.tbz"
      end

      # Return false if no url was suggested or file does not exist
      raise AppleEpf::DownloaderError.new("Unable to find out what file do you want to download") if path.empty?

      unless file_exists?(path)
        if @type == 'incremental'
          #force prev week. Apple sometimes put files for Sunday to prev week, not current.
          path = "#{main_dir_date(true)}/incremental/#{date_of_file}/#{@filename}#{date_of_file}.tbz"
          raise AppleEpf::FileNotExist.new("File does not exist #{path}") unless file_exists?(path)
        else
          raise AppleEpf::FileNotExist.new("File does not exist #{path}")
        end
      end

      @apple_filename_full_path = path
      @apple_filename_full_path
    end

    def downloaded_file_base_name
      File.basename(@download_to, '.tbz') #popularity20130109
    end

    private

    def apple_filename_full_url(path)
      File.join(ITUNES_FLAT_FEED_URL, path)
    end

    def _prepare_folders
      logger_info "Create folders for path: #{dirpath}"
      FileUtils.mkpath(dirpath)
    end

    def main_dir_date(force_last = false)
      if @type == "incremental"
        # from Mon to Thurday dumps are in prev week folder
        this_or_last = @filedate.wday <= 4 || force_last ? 'last' : 'this'
      elsif @type == "full"
        # full downloads usually are done only once. user can determine when it should be done
        this_or_last = 'this'
      end

      main_folder_date = Chronic.parse("#{this_or_last} week wednesday", :now => @filedate.to_time).to_date
      date_to_epf_format(main_folder_date)
    end

    def date_to_epf_format(date)
      date.strftime("%Y%m%d")
    end

    def file_exists?(path_to_check)
      full_url = apple_filename_full_url(path_to_check)
      logger_info "Checking file at URL: #{full_url}"

      uri = URI.parse(full_url)

      request = Net::HTTP::Head.new(full_url)
      request.basic_auth(AppleEpf.apple_id, AppleEpf.apple_password)

      r = Net::HTTP.new(uri.host, uri.port)
      r.use_ssl = true
      response = r.start { |http| http.request(request) }

      raise AppleEpf::BadCredentialsError.new('Bad credentials') if response.code == "401"

      response.code == "200"
    end

    def start_download
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
          start_download
        else
          raise AppleEpf::CurlError.new("Unable to download file.")
        end
      end
    end

  end
end