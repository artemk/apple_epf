require 'nokogiri'

module AppleEpf
  class Main
    attr_reader :downloader, :filedate, :files_matrix
    attr_accessor :store_dir, :keep_tbz_after_extract

    def initialize(filedate, files_matrix = nil, store_dir = nil, keep_tbz_after_extract = nil)
      @filedate = filedate
      @files_matrix = files_matrix || AppleEpf.files_matrix
      @store_dir = store_dir
      @keep_tbz_after_extract = !!keep_tbz_after_extract || AppleEpf.keep_tbz_after_extract
    end

    def self.get_current_list
        curl = Curl::Easy.new(self.current_url)
        curl.http_auth_types = :basic
        curl.username = AppleEpf.apple_id
        curl.password = AppleEpf.apple_password
        curl.follow_location = true
        curl.max_redirects = 5
        curl.perform
        body = curl.body_str

        files =  Nokogiri::HTML(body).xpath("//td/a").map(&:text).select{|s| s=~/.*tbz$/}

        files.inject({}) do |all, e|
          e.match(/([a-z]*)(\d*.tbz)/)
          all[$1] = {}
          all[$1][:base] = $2.chomp(".tbz")
          all[$1][:full_url] = self.current_url + "/#{$1}#{$2}"
          all
        end
    end

    module BaseActions
      def download_all_files(&block)
        downloaded_files = []

        @files_matrix.each_pair do |filename, extractables|
          begin
            downloaded = self.download(filename)
            downloaded_files << downloaded
            block.call(downloaded) if block_given?
          rescue AppleEpf::DownloaderError
            AppleEpf::Logging.logger.fatal "Failed to download file #{filename}"
            AppleEpf::Logging.logger.fatal $!
            next
          end
        end

        downloaded_files
      end

      def download_and_extract_all_files(&block)
        extracted_files = []

        @files_matrix.each_pair do |filename, extractables|
          begin
            extracted_file = download_and_extract(filename.to_s, extractables)
            extracted_files << extracted_file
            block.call(extracted_file) if block_given?
          rescue
            AppleEpf::Logging.logger.fatal "Failed to download and parse file #{filename}"
            next
          end
        end

        extracted_files
      end

      # will return array of filepath of extracted files
      def download_and_extract(filename, extractables)
        downloader = self.download(filename.to_s)
        downloaded_file = downloader.download_to
        self.extract(downloaded_file, extractables)
      end

      def download(filename)
        downloader = AppleEpf::Downloader.new(type, filename.to_s, @filedate)
        downloader.dirpath = @store_dir if @store_dir
        downloader.download
        downloader
      end

      def extract(downloaded_file, extractables)
        extractor = AppleEpf::Extractor.new(downloaded_file, extractables)
        extractor.keep_tbz_after_extract = @keep_tbz_after_extract if @keep_tbz_after_extract
        extractor.perform
        extractor.file_entry
      end
    end
  end

  class Incremental <  Main
    include BaseActions

    def type
      'incremental'
    end

    def self.current_url
      'https://feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current'
    end
  end

  class Full < Main
    include BaseActions

    def type
      'full'
    end

    def self.current_url
      'https://feeds.itunes.apple.com/feeds/epf/v3/full/current'
    end
  end

end
