# encoding: UTF-8
require File.expand_path('../../../spec_helper', __FILE__)

describe AppleEpf::Extractor do
  let(:file_basename) { 'itunes20130111.tbz' }
  let(:files_to_extract) { ['application', 'test_file.txt'] }

  before do
    @tmp_dir = [Dir.tmpdir, 'test_epm_files'].join('/')
    FileUtils.mkpath @tmp_dir

    AppleEpf.configure do |config|
      config.apple_id = 'test'
      config.apple_password = 'test'
      config.extract_dir = @tmp_dir
    end

    @copy_to = "#{@tmp_dir}/#{file_basename}"
    FileUtils.copy_file(apple_epf_inc_filename(file_basename), @copy_to)
  end

  after do
    FileUtils.remove_dir(@tmp_dir)
  end

  describe "initialize" do
    it "should set instance variables" do
      extractor = AppleEpf::Extractor.new(@copy_to, files_to_extract)

      extractor.filename.should == @copy_to
      extractor.dirname.should == @tmp_dir
      extractor.basename.should == file_basename
    end
  end

  describe "perform" do
    it "should raise error if extracting was not successful" do
      files_to_extract = ['application', 'wrong_file.txt']
      extractor = AppleEpf::Extractor.new(@copy_to, files_to_extract)

      expect {
        extractor.perform
      }.to raise_exception ("Unable to extract files '#{files_to_extract.join(' ')}' from #{@copy_to}")
    end

    it "should return list if extracted files" do
      extractor = AppleEpf::Extractor.new(@copy_to, files_to_extract)
      extractor.perform
      extractor.file_entry.tbz_file.should == @copy_to

      expected_extracted = files_to_extract.map do |f|
        File.join(@tmp_dir, 'itunes20130111', f)
      end

      extractor.file_entry.extracted_files.should == Hash[files_to_extract.zip(expected_extracted)]
      extractor.file_entry.tbz_file.should == @copy_to
    end

    it "should remove file if successfully untarred" do
      extractor = AppleEpf::Extractor.new(@copy_to, files_to_extract)
      extractor.perform
      File.exists?(extractor.filename).should be_false
    end

    it "should not remove file if successfully untarred and it was asked to leave file" do
      extractor = AppleEpf::Extractor.new(@copy_to, files_to_extract)
      extractor.keep_tbz_after_extract = true
      extractor.perform
      File.exists?(extractor.filename).should be_true
    end
  end
end