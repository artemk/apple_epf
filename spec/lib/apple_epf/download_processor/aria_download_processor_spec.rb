# encoding: UTF-8
require File.expand_path('../../../../spec_helper', __FILE__)
require 'rack'

describe AppleEpf::AriaDownloadProcessor, pending: 'Do not test this' do
  describe "download" do
    before(:all) do
      @mockServer = Rack::File.new(apple_epf_dir)
      @server_thread = Thread.new do
        Rack::Handler::WEBrick.run @mockServer, :Port => 4400
      end
      sleep(2)
    end

    after(:all) do
      @server_thread.kill
    end

    before do
      @tmp_dir = [Dir.tmpdir, 'epm_files'].join('/')

      FileUtils.mkpath @tmp_dir

      AppleEpf.configure do |config|
        config.apple_id = 'test'
        config.apple_password = 'test'
        config.extract_dir = @tmp_dir
      end

    end

    after do
      FileUtils.remove_dir(@tmp_dir)
    end

    it "should process if md5 is fine" do
      downloader = AppleEpf::AriaDownloadProcessor.new("http://localhost:4400/popularity20130111.tbz", "#{@tmp_dir}/popularity20130111.tbz")

      #correct md5
      downloader.instance_variable_set(:@md5_checksum, '6fad1fb7823075d92296260fae3e317e')
      downloader.download

      File.read("#{@tmp_dir}/popularity20130111.tbz").should ==
        File.read(apple_epf_inc_filename('popularity20130111.tbz'))
    end

    it "should return error if md5 is not correct" do
      downloader = AppleEpf::AriaDownloadProcessor.new("http://localhost:4400/popularity20130111.tbz", "#{@tmp_dir}/popularity20130111.tbz")

      downloader.instance_variable_set(:@md5_checksum, '0371a79664856494e840af9e1e6c0152')
      expect {
        downloader.download
      }.to raise_error(AppleEpf::DownloaderError)
    end

    it 'should return error if file is not found' do
      downloader = AppleEpf::AriaDownloadProcessor.new("http://localhost:4400/popularity20130112.tbz", "#{@tmp_dir}/popularity20130112.tbz")

      downloader.instance_variable_set(:@md5_checksum, '0371a79664856494e840af9e1e6c0152')
      expect {
        downloader.download
      }.to raise_error(AppleEpf::DownloaderError)
    end

    describe "download_and_check" do
      it "should download md5 and file and compare" do
        downloader = AppleEpf::AriaDownloadProcessor.new("http://localhost:4400/popularity20130111.tbz", "#{@tmp_dir}/popularity20130111.tbz")

        stub_request(:get, "http://test:test@localhost:4400/popularity20130111.tbz.md5").
          to_return(:status => 200, :body => "MD5 (popularity20130111.tbz) = 6fad1fb7823075d92296260fae3e317e\n", :headers => {})

        expect {
          downloader.download_and_check
        }.to_not raise_error
      end

    end
  end
end
