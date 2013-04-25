# encoding: UTF-8
require File.expand_path('../../../spec_helper', __FILE__)

describe AppleEpf::Downloader do

  let(:type) { 'incremental' }
  let(:filedate) { Date.parse('17-01-2013') }
  let(:file) { 'popularity' }
  let(:downloader) {AppleEpf::Downloader.new(type, file, filedate)}
  let(:file_exists) { true }

  describe "#get_filename_by_date_and_type" do
    before do
      downloader.stub(:file_exists?){ file_exists }
    end

    it "should raise exception if path can not be determined" do
      downloader.type = 'crazytype'
      expect {
        downloader.get_filename_by_date_and_type
      }.to raise_exception
    end

    context "type is full" do
      let(:type) { 'full' }

      context "and file exists" do
        let(:file_exists) { true }

        it "should return valid url if file exists" do
          downloader.filedate = Date.parse('17-01-2013')
          downloader.get_filename_by_date_and_type.should == "20130116/popularity20130116.tbz"
        end
      end

      context "and file does not exists" do
        let(:file_exists) { false }

        it "should raise exception" do
          downloader.filedate = Date.parse('17-01-2013')
          expect {
            downloader.get_filename_by_date_and_type
          }.to raise_exception(AppleEpf::FileNotExist)
        end
      end

    end

    context "type is incremental" do
      let(:type) { 'incremental' }

      context "and file exists" do
        let(:file_exists) { true }

        it "should return valid url if file exists" do
          downloader.filedate = Date.parse('17-01-2013')
          downloader.get_filename_by_date_and_type.should == "20130109/incremental/20130117/popularity20130117.tbz"
        end
      end

      context "and file does not exists" do
        let(:file_exists) { false }

        it "should raise exception" do
          downloader.filedate = Date.parse('17-01-2013')
          expect {
            downloader.get_filename_by_date_and_type
          }.to raise_exception(AppleEpf::FileNotExist)
        end
      end

    end

    context "type is file" do
      pending
    end

  end

  describe "#main_dir_date" do

    context "full" do
      let(:type) { 'full' }
      it "should return the same week wednesday" do
        downloader.filedate = Date.parse('17-01-2013') #thursday
        downloader.send(:main_dir_date).should == "20130116"
      end
      # it "should return wednesday of this week if filedate is thur-sun" do
      #   downloader.filedate = Date.parse('17-01-2013') #thursday
      #   downloader.send(:main_dir_date).should == "20130116"

      #   downloader.filedate = Date.parse('19-01-2013') #sut
      #   downloader.send(:main_dir_date).should == "20130116"
      # end

      # it "should return wednesday of prev week if filedate is mon-wed" do
      #   downloader.filedate = Date.parse('21-01-2013') #monday
      #   downloader.send(:main_dir_date).should == "20130123"

      #   downloader.filedate = Date.parse('23-01-2013') #wednesday
      #   downloader.send(:main_dir_date).should == "20130123"
      # end
    end

    context "incremental" do
      let(:type) { 'incremental' }
      it "should return wednesday of this week if filedate is friday-sunday" do
        downloader.filedate = Date.parse('18-01-2013') #friday
        downloader.send(:main_dir_date).should == "20130116"

        downloader.filedate = Date.parse('19-01-2013') #sut
        downloader.send(:main_dir_date).should == "20130116"
      end

      it "should return wednesday of prev week if filedate is monday-thursday" do
        downloader.filedate = Date.parse('21-01-2013') #monday
        downloader.send(:main_dir_date).should == "20130116"

        downloader.filedate = Date.parse('24-01-2013') #thursday
        downloader.send(:main_dir_date).should == "20130116"
      end
    end
  end

  describe "download" do
    let(:filedate) { Date.parse('21-01-2013') }

    before do
      @tmp_dir = [Dir.tmpdir, 'epm_files'].join('/')
      FileUtils.mkpath @tmp_dir

      AppleEpf.configure do |config|
        config.apple_id = 'test'
        config.apple_password = 'test'
        config.extract_dir = @tmp_dir
      end

      downloader.stub(:download_and_compare_md5_checksum)
    end

    it "should properly set url for download" do
      downloader.stub(:file_exists?){ file_exists }
      downloader.stub(:start_download)
      downloader.download
      downloader.apple_filename_full.should eq("https://feeds.itunes.apple.com/feeds/epf/v3/full/20130116/incremental/20130121/popularity20130121.tbz")
    end

    it "should properly set local file to store file in" do
      downloader.stub(:file_exists?){ file_exists }
      downloader.stub(:start_download)
      downloader.download
      downloader.download_to.should eq("#{@tmp_dir}/incremental/popularity20130121.tbz")
    end

    it "should download and save file" do
      stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/20130123/popularity20130123.tbz").
        to_return(:status => 200, :body => "Test\nWow", :headers => {})

      downloader = AppleEpf::Downloader.new('full', file, filedate)
      downloader.stub(:download_and_compare_md5_checksum)
      downloader.stub(:file_exists?){ file_exists }
      downloader.download
      IO.read(downloader.download_to).should eq("Test\nWow")
    end

    it "should retry 3 times to download" do
      pending
    end

    describe "dirpath" do
      before do
        downloader.stub(:file_exists?){ file_exists }
        downloader.stub(:start_download)
      end

      it "should be able to change dir where to save files" do
        tmp_dir = Dir.tmpdir
        downloader.dirpath = [tmp_dir, 'whatever_path'].join('/')
        downloader.download.should ==  "#{tmp_dir}/whatever_path/incremental/popularity20130121.tbz"
      end
    end

    describe "#download_and_compare_md5_checksum" do
      before do
        downloader.unstub(:download_and_compare_md5_checksum)
      end
      it "should raise exception if md5 file does not match real md5 checksum of file" do
        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/20130116/incremental/20130121/popularity20130121.tbz").
          to_return(:status => 200, :body => "Test\nWow", :headers => {})

        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/20130116/incremental/20130121/popularity20130121.tbz.md5").
          to_return(:status => 200, :body => "tupo", :headers => {})

        downloader.stub(:file_exists?){ file_exists }

        expect {
          downloader.download
        }.to raise_exception(AppleEpf::Md5CompareError)

      end

      it "should not raise exception if md5 is ok" do
        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/20130116/incremental/20130121/popularity20130121.tbz").
          to_return(:status => 200, :body => "Test\nWow", :headers => {})

        stub_request(:get, "https://test:test@feeds.itunes.apple.com/feeds/epf/v3/full/20130116/incremental/20130121/popularity20130121.tbz.md5").
          to_return(:status => 200, :body => "MD5 (popularity20130116.tbz) = 0371a79664856494e840af9e1e6c0152\n", :headers => {})


        downloader.stub(:file_exists?){ file_exists }

        expect {
          downloader.download
        }.not_to raise_exception(AppleEpf::Md5CompareError)

      end
    end
  end

end