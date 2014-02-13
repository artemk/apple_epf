# encoding: UTF-8
require File.expand_path('../../../spec_helper', __FILE__)

describe AppleEpf::Main do
  let(:filedate) { Date.parse('17-01-2013') }
  let(:file_entry_double) { double('FileEntry', tbz_file: 'tbz_file') }
  let(:file_basename) { 'itunes20130111.tbz' }

  before do
    @tmp_dir = [Dir.tmpdir, 'epm_files'].join('/')
    FileUtils.mkpath @tmp_dir

    AppleEpf.configure do |config|
      config.apple_id = 'test'
      config.apple_password = 'test'
      config.extract_dir = @tmp_dir
      config.files_matrix = {popularity: ['application_popularity_per_genre']}.freeze
    end
  end

  describe "initialize" do
    it "should set attributes" do
      custom_dir = [Dir.tmpdir, 'epm_files_custom'].join('/')
      manager = AppleEpf::Incremental.new(filedate, nil, custom_dir)

      manager.store_dir.should == custom_dir
      manager.filedate.to_s.should == Date.parse('17-01-2013').to_s
      manager.store_dir.should == custom_dir
      manager.files_matrix.should == {popularity: ['application_popularity_per_genre']}

      manager = AppleEpf::Incremental.new(filedate, {test: ['itworks']})
      manager.files_matrix.should == {test: ['itworks']}

    end
  end

  describe "#download_all_files" do
    before do
      files_matrix = {one: ['test1', 'test2'], two: ['test3', 'test4']}
      @manager = AppleEpf::Incremental.new(filedate, files_matrix)

      @downloder_double1 = double('Downloader', download: true, download_to: 'somepath')
      @downloder_double2 = double('Downloader', download: true, download_to: 'somepath2')

      AppleEpf::Downloader.should_receive(:new).with('incremental', 'one', filedate).and_return(@downloder_double1)
      AppleEpf::Downloader.should_receive(:new).with('incremental', 'two', filedate).and_return(@downloder_double2)
    end

    it "should download all files and return array with donwloaded files" do
      @manager.download_all_files.should == [@downloder_double1, @downloder_double2]
    end

    it "should send to block if block given" do
      expect { |b|
        @manager.download_all_files(&b)
      }.to yield_successive_args(*[@downloder_double1, @downloder_double2])
    end
  end

  describe "#download_and_extract_all_files" do
    before do
      @itunes_download_to = "#{@tmp_dir}/itunes20130111.tbz"
      FileUtils.copy_file(apple_epf_inc_filename('itunes20130111.tbz'), @itunes_download_to)

      @popularity_download_to = "#{@tmp_dir}/popularity20130111.tbz"
      FileUtils.copy_file(apple_epf_inc_filename('popularity20130111.tbz'), @popularity_download_to)

      itunes_downloder_double = double('Downloader', download: true, download_to: @itunes_download_to)
      popularity_downloder_double = double('Downloader', download: true, download_to: @popularity_download_to)

      @file_matrix = {
                        itunes: ['application', 'test_file.txt'],
                        popularity: ['popularity1', 'popularity2'],
                      }

      @manager = AppleEpf::Incremental.new(filedate, @file_matrix)

      AppleEpf::Downloader.should_receive(:new)
        .with('incremental', 'itunes', filedate).and_return(itunes_downloder_double)

      AppleEpf::Downloader.should_receive(:new)
        .with('incremental', 'popularity', filedate).and_return(popularity_downloder_double)

      @itunes_expected_extracted = ['application', 'test_file.txt'].map do |f|
        File.join(@tmp_dir, 'itunes20130111', f)
      end

      @popularity_expected_extracted = ['popularity1', 'popularity2'].map do |f|
        File.join(@tmp_dir, 'popularity20130111', f)
      end
    end

    it "should download all files and return array with donwloaded files" do
      result = @manager.download_and_extract_all_files
      result.map(&:extracted_files).should == [
        Hash[['application', 'test_file.txt'].zip(@itunes_expected_extracted)],
        Hash[['popularity1', 'popularity2'].zip(@popularity_expected_extracted)]
      ]
    end

    it "should send to block if block given" do
      expect { |b|
        @manager.download_and_extract_all_files(&b)
      }.to yield_successive_args(AppleEpf::Extractor::FileEntry, AppleEpf::Extractor::FileEntry)
    end
  end

  describe "#download_and_extract" do
    it "should return extracted files" do
      @download_to = "#{@tmp_dir}/#{file_basename}"
      FileUtils.copy_file(apple_epf_inc_filename(file_basename), @download_to)

      downloder_double = double('Downloader', download: true, download_to: @download_to)

      manager = AppleEpf::Incremental.new(filedate)
      AppleEpf::Downloader.should_receive(:new).and_return(downloder_double)

      result = manager.download_and_extract('itunes', ['application', 'test_file.txt'])
      expected_extracted = ['application', 'test_file.txt'].map do |f|
        File.join(@tmp_dir, 'itunes20130111', f)
      end

      result.extracted_files.should == Hash[['application', 'test_file.txt'].zip(expected_extracted)]
    end
  end

  describe "#download" do
    it "should download file and return path to downloaded file" do
      manager = AppleEpf::Incremental.new(filedate)

      downloder_double1 = double('Downloader', download: true, download_to: 'somepath')

      AppleEpf::Downloader.should_receive(:new).with('incremental', 'one', filedate).and_return(downloder_double1)

      manager.download('one').download_to.should == 'somepath'
    end

  end

  describe "#extract" do
    it "should extract and return file entry" do
      file = Tempfile.new('foo.tbz')
      extractor_double = double('Ectractor', file_entry: file_entry_double).as_null_object

      manager = AppleEpf::Incremental.new(filedate)
      AppleEpf::Extractor.should_receive(:new).with(file, ['extractable1']).and_return(extractor_double)

      manager.extract(file, ['extractable1']).should == file_entry_double

    end
  end


  describe ".get_current_list" do
    context 'Full' do
      let(:filename) { apple_epf_filename('current_full_list.html') }

      it "should return hash of avaliable files" do
        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/current").
          to_return(:status => 200, :body => File.read(filename), :headers => {})

        list = {
          "itunes" => {:base=>"20130130", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/itunes20130130.tbz"},
          "match" => {:base=>"20130130", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/match20130130.tbz"},
          "popularity" => {:base=>"20130130", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/popularity20130130.tbz"},
          "pricing" => {:base=>"20130130", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/pricing20130130.tbz"}
        }
        AppleEpf::Full.get_current_list.should == list
      end

    end

    context "Incremental" do
      let(:filename) { apple_epf_filename('current_inc_list.html') }

      it "should return hash of avaliable files" do
        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current").
          to_return(:status => 200, :body => File.read(filename), :headers => {})

        list = {
          "itunes" => {:base=>"20130205", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current/itunes20130205.tbz"},
          "match" => {:base=>"20130205", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current/match20130205.tbz"},
          "popularity" => {:base=>"20130205", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current/popularity20130205.tbz"},
          "pricing" => {:base=>"20130205", :full_url=>"https://feeds.itunes.apple.com/feeds/epf/v3/full/current/incremental/current/pricing20130205.tbz"}
        }
        AppleEpf::Incremental.get_current_list.should == list
      end
    end
  end
end
