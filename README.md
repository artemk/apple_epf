# AppleEpf

## Installation

    gem 'apple_epf'

## Setup

  Put this in your initializer.rb if you are using Rails.

    AppleEpf.configure do |config|
      config.apple_id = 'username'
      config.apple_password = 'password'
      config.download_retry_count = 3 #
      config.keep_tbz_after_extract = false
      config.extract_dir = '' # where to extract to
      config.log_file = 'path to log file' #absolute path to log file
      config.files_matrix = {} # {popularity: ['application_popularity_per_genre']}
    end

  All of this can be redefined for every downloader.

## Manual manipulations

    # Manually download one file
    downloader = AppleEpf::Downloader.new('incremental', 'popularity', Date.parse('17-01-2013'))
    downloader.download #=> will return local filepath to downloaded file or fire exception


    # Manually extract one archive
    extractor = AppleEpf::Extractor.new(filename, files_to_extract)
    # filename - full path to local file
    # files_to_extract - Files to be extracted from Archive (application, application_detail)
    file_entry = extractor.perform #=> will return instance of FileEntry
    file_entry.tbz_file #=> original file that was parsed. It is removed after untaring
    file_entry.extracted_files #=> newly created(unpacked) files

    #Manually parse file
    parser = AppleEpf::Parser.new(filename, header_block, row_block)
    # filename - full local path to file
    # header_block - will return header info from file
    # row_block - will return each row from file

## Download and Extract
  If you want to combine downloading and extracting your can use one of following
  methonds. My personal feeling is to parsing should we something live alone and should not be combined in one stack with download and extract. And of cource it is better to download and extract files one by one.

    manager = AppleEpf::Incremental.new('10-10-2012', {popularity: ['application_popularity_per_genre']})

    manager = AppleEpf::Full.new('10-10-2012', {popularity: ['application_popularity_per_genre']})

    manager.download_all_files #will download all files for this date for all keys "popularity", 'pricing', 'itunes' etc

    manager.download_and_extract_all_files #will first download and than extract all files

    manager.download_and_extract('itunes', ['application', 'application_detail']) #will donwload only 'itunes' and extract only ['application', 'application_detail']. This actually ignored matrix passed to initializer

    manager.download('itunes') #will only download file

  You can omit where to store files by setting it directly to downloader instance

    manager.store_dir = '/whatever_dir_you_like'
    manager.download('itunes')

  OR

    downloader = AppleEpf::Downloader.new('incremental', 'popularity', Date.parse('17-01-2013'))
    downloader.dirpath = '/whatever_dir_you_like'
    downloader.download

  You can also omit if you want to store initial tbz files after they will be unpacked

    extractor.keep_tbz_after_extract = true

  OR

    manager.keep_tbz_after_extract = true


## Get list of current files avaliable for download

  AppleEpf::Incremental.get_current_list #=> current incremental files
  AppleEpf::Full.get_current_list #=> current full files
