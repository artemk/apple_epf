# encoding: UTF-8
require File.expand_path('../../../spec_helper', __FILE__)

describe AppleEpf::Parser do
  let(:header_block) {Proc.new{|b|}}
  let(:row_block) {Proc.new{|b|}}
  let(:filename) { apple_epf_inc_filename('itunes20130111/application') }

  let(:parser) {AppleEpf::Parser.new(filename)}

  describe "perform" do

    describe "#parse_metadata" do

      it "should properly parse header" do
        _header_info = {:file=> "application",
                        :columns=>["export_date", "application_id", "title",
                                  "recommended_age", "artist_name", "seller_name",
                                  "company_url", "support_url", "view_url",
                                  "artwork_url_large", "artwork_url_small",
                                  "itunes_release_date", "copyright",
                                  "description", "version", "itunes_version",
                                  "download_size"],
                        :primary_keys=>["application_id"],
                        :db_types=>["BIGINT", "INTEGER", "VARCHAR(1000)", "VARCHAR(20)",
                                    "VARCHAR(1000)", "VARCHAR(1000)", "VARCHAR(1000)",
                                    "VARCHAR(1000)", "VARCHAR(1000)", "VARCHAR(1000)",
                                    "VARCHAR(1000)", "DATETIME", "VARCHAR(4000)",
                                    "LONGTEXT", "VARCHAR(100)", "VARCHAR(100)", "BIGINT"],
                        :export_type=>["INCREMENTAL"]}

        _footer_info = {:records=>"2"}

        parser.parse_metadata.should eq(_header_info.merge(_footer_info))
      end

      it "should properly parse footer" do
        _footer_info = {:records=>"2"}
        parser.parse_metadata
        parser.footer_info.should eq(_footer_info)
      end
    end

    describe "#process_rows" do
      it "should properly parse body" do
        first_entry = ["1111111111", "1111111111", "1111111111", "4+", "1111111111", "1111111111", "", "http://static.f1111111111.com/support", "http://itunes.apple.cdcdcd/app/1111111111/id1111111111uo=5", "http://a3.mzstatic.com/us/r1000/112/Purple/v4/cdcdcd/e0/e8/1111111111-2398-c014-2aae-8aefc7cd0f1c/mzl.hbggcdah.100x100-75.jpg", "http://a3.dccdcd.com/us/r1000/116/Purple/v4/66/ea/39/1111111111-c19f-4f01-475e-71fbd2d864a1/Icdcdcdon.png", "2012 03 06", "© Freedomeat, Inc.", "1111111111", "2.1.0", "11111111110", "1111111111"]
        second_entry = ["1111111111", "41111111111", "Sp1111111111free", "4+", "L1111111111a", "L1111111111va", "http://www.s1111111111q.pl", "http://www.1111111111.pl", "http://itunes.apple.com/app/1111111111-1111111111-free/id1111111111?uo=5", "http://a2.mzstatic.com/us/r1000/071/Purple/v4/d4/68/01/d1111111111f9ba-ba6c-43c306364299/temp..bsoykdqd.100x100-75.jpg", "http://a3.mzstatic.com/us/r1000/1111111111e3/0f/71e30f60-142f-5f03-3558-1c8a0c383e42/Icon.png", "2011 03 14", "© Linnova", "Sprawdź 1111111111\nRazem - ponad 650 słów i fraz tj. ponad 1000 profesjonalnych nagrań dźwi1111111111\n1111111111\n\n*More on www1111111111us", "2.1.3", "1273444446", "21444440"]
        third_entry = ["134444270", "5411111111111", "Wh1111111111iz", "4+", "App1111111111td", "App1111111111d", "", "http://appe1111111111t.com", "http://itunes.apple.com/app/what1111111111id5111111111131?uo=5", "http://a5.mzstatic.com/us/r1000/101/Purple/v4/bd/39/44/bd39449d11111111111e8-4de4083899e0/mzm.kuywoxgn.100x100-75.jpg", "http://a1.mzstatic.com/us1111111111/v4/95/2c/75/952c7576-6196-11a7-42be-9f3822e9d084/icon.png", "2011111111119", "© Apperleft Ltd", "\n- Original exciting themes and levels\n- Test your knowledge\n- Use Bombs to narrow the letters selection\n- Challenging Themes and Levels\n\n- Compatible with all devices iPod/iPhone/iPad/New iPad\n- Free update keep coming\n!", "1.4", "14111111111139", "1411111111115"]

        expect { |b|
         parser.process_rows(&b)
        }.to yield_successive_args(*[first_entry, second_entry, third_entry])
      end

      it "should return nil for blank data" do
        first_entry = ["1111111111", "1111111111", "1111111111", "4+", "1111111111", "1111111111", "", "http://static.f1111111111.com/support", "http://itunes.apple.cdcdcd/app/1111111111/id1111111111uo=5", "http://a3.mzstatic.com/us/r1000/112/Purple/v4/cdcdcd/e0/e8/1111111111-2398-c014-2aae-8aefc7cd0f1c/mzl.hbggcdah.100x100-75.jpg", "http://a3.dccdcd.com/us/r1000/116/Purple/v4/66/ea/39/1111111111-c19f-4f01-475e-71fbd2d864a1/Icdcdcdon.png", "2012 03 06", "© Freedomeat, Inc.", "1111111111", "2.1.0", "11111111110", '']
        parser = AppleEpf::Parser.new(apple_epf_inc_filename('itunes20130111/application_with_nil'))
        expect { |b|
         parser.process_rows(&b)
        }.to yield_successive_args(*[first_entry])
      end
    end


  end
end