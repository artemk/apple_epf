require 'tmpdir'
require 'fileutils'
require 'chronic'
require 'core_ext/array'
require 'core_ext/module'
require 'apple_epf/errors'
require 'apple_epf/logging'
require 'apple_epf/main'
require 'apple_epf/download_processor'
require 'apple_epf/downloader'
require 'apple_epf/extractor'
require 'apple_epf/parser'

module AppleEpf
  FILE_TYPES = %w( full incremental )

  mattr_accessor :apple_id
  @@apple_id = "test"

  mattr_accessor :apple_password
  @@apple_password = "test"

  mattr_accessor :download_retry_count
  @@download_retry_count = 3

  mattr_accessor :concurrent_downloads
  @@concurrent_downloads = 2

  mattr_accessor :download_processor
  @@download_processor = AppleEpf::CurbDownloadProcessor

  mattr_accessor :keep_tbz_after_extract
  @@keep_tbz_after_extract = false

  mattr_accessor :extract_dir
  @@extract_dir = [Dir.tmpdir, 'epm_files'].join('/')

  mattr_accessor :log_to_console
  @@keep_tbz_after_extract = log_to_console

  mattr_accessor :log_file
  @@log_file = '/dev/null'

  mattr_accessor :files_matrix
  @@files_matrix = {popularity: ['application_popularity_per_genre']}.freeze

  def self.configure
    yield self
  end
end
