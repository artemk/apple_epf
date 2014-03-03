require 'net/http'
require 'date'
require 'curb'
require 'digest/md5'

module AppleEpf
  class Downloader
    include AppleEpf::Logging
    ITUNES_FLAT_FEED_URL = 'https://feeds.itunes.apple.com/feeds/epf/v3/full'.freeze

    attr_accessor :type, :filename, :filedate, :force_url

    attr_reader :download_to, :apple_filename_full
    attr_writer :dirpath
    def initialize(type, filename, filedate, force_url = nil)
      @type = type
      @filename = filename #itunes, popularity, match, pricing
      @filedate = filedate
      @force_url = force_url
    end

    def prepare
      _prepare_folders
      if @force_url
        @apple_filename_full = @force_url
      else
        get_filename_by_date_and_type
        @apple_filename_full = apple_filename_full_url(@apple_filename_full_path)
      end
      @download_to = File.join(dirpath, File.basename(@apple_filename_full))
    end

    def download
      prepare
      @download_processor = AppleEpf.download_processor.new(@apple_filename_full, @download_to)
      @download_processor.download_and_check
      @download_to
    end

    def dirpath
      File.join((@dirpath || AppleEpf.extract_dir), @type)
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
  end
end
