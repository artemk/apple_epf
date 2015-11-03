module AppleEpf
  class Extractor
    class FileEntry <  Struct.new(:tbz_file, :extracted_files); end

    attr_reader :file_entry, :filename, :dirname, :basename
    attr_accessor :keep_tbz_after_extract

    def initialize(filename, files_to_extract)
      @filename = filename
      @files_to_extract = files_to_extract

      @dirname = File.dirname(@filename)
      @basename = File.basename(@filename)
    end

    #TODO use multithread uncompressing tool
    def perform
      @extracted_files = Array.new
      @files_to_extract.each do |f|
        @extracted_files.push File.basename(@filename, '.tbz') + '/' + f
      end

      extract = extract_command(@basename, @extracted_files.join(' '))

      result = system "cd #{@dirname} && #{extract}"

      if result
        _extracted_files = @extracted_files.map{|f| File.join(@dirname, f)}
        @file_entry = FileEntry.new(@filename, Hash[@files_to_extract.zip(_extracted_files)])
        FileUtils.remove_file(@filename, true) unless keep_tbz_after_extract?
      else
        raise "Unable to extract files '#{@files_to_extract.join(' ')}' from #{@filename}"
      end

      @file_entry
    end

    private

    def extract_command(filename, files_to_extract)
      opts = archiver_opts
      "#{archiver_path} #{opts} #{filename} #{files_to_extract}"
    end

    def archiver_path
      AppleEpf.archiver_path
    end

    def archiver_opts
      if AppleEpf.use_lbzip2
        format_opt = "--use-compress-program=lbzip2"
      else
        format_opt = "-j"
      end

      if AppleEpf.archiver == :gnutar
        "-x #{format_opt} -f"
      elsif AppleEpf.archiver == :bsdtar
        "-x #{format_opt}"
      end
    end

    def keep_tbz_after_extract?
      !!keep_tbz_after_extract || AppleEpf.keep_tbz_after_extract
    end
  end
end
