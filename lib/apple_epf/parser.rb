module AppleEpf
  class Parser
    FIELD_SEPARATOR = 1.chr
    RECORD_SEPARATOR = 2.chr + "\n"
    COMMENT_CHAR = '#'

    attr_accessor :filename, :header_info, :footer_info

    def initialize(filename)
      @filename = filename
      @header_info = {}
      @footer_info = {}
    end

    def parse_metadata
      begin
        parse_file
        load_header_info
        load_footer_info
        @header_info.merge(@footer_info)
      ensure
        close_file
      end
    end

    def process_rows(&block)
      File.foreach( @filename, RECORD_SEPARATOR ) do |line|
        unless line[0].chr == COMMENT_CHAR
          line = line.chomp( RECORD_SEPARATOR )
          block.call( line.split( FIELD_SEPARATOR, -1) ) if block_given?
        end
      end
    end

    private

    def parse_file
      @file = File.new( @filename, 'r', encoding: 'UTF-8' )
    end

    def close_file
      @file.close if @file
    end

    def read_line(accept_comment = false)
      valid_line = false
      until valid_line
        begin
          line = @file.readline( RECORD_SEPARATOR )
        rescue EOFError => e
          return nil
        end
        valid_line = accept_comment ? true : !line.start_with?( COMMENT_CHAR )
      end
      line.sub!( COMMENT_CHAR, '' ) if accept_comment
      line.chomp!( RECORD_SEPARATOR )
    end

    def load_header_info
      # File
      file_hash = { :file => File.basename( @filename ) }
      @header_info.merge! ( file_hash )

      # Columns
      line = read_line(true)
      column_hash = { :columns => line.split( FIELD_SEPARATOR ) }
      @header_info.merge! ( column_hash )

      # Primary keys
      line = read_line(true).sub!( 'primaryKey:', '' )
      primary_hash = { :primary_keys => line.split( FIELD_SEPARATOR ) }
      @header_info.merge! ( primary_hash )

      # DB types
      line = read_line(true).sub!( 'dbTypes:', '' )
      primary_hash = { :db_types => line.split( FIELD_SEPARATOR ) }
      @header_info.merge! ( primary_hash )

      # Export type
      line = read_line(true).sub!( 'exportMode:', '' )
      primary_hash = { :export_type => line.split( FIELD_SEPARATOR ) }
      @header_info.merge! ( primary_hash )
    end


    def load_footer_info
      @file.seek(-40, IO::SEEK_END)
      records = @file.read.split( COMMENT_CHAR ).last.chomp!( RECORD_SEPARATOR ).sub( 'recordsWritten:', '' )
      records_hash = { :records => records }
      @footer_info.merge! ( records_hash )
      @file.rewind
      @footer_info
    end
  end
end