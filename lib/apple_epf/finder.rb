module AppleEpf
  module Finder
    extend self
    ITUNES_FULL_URL = "https://feeds.itunes.apple.com/feeds/epf/v3/full/".freeze
    ITUNES_INCREMENTAL_URL = "https://feeds.itunes.apple.com/feeds/epf/v3/full/%s/incremental/".freeze

    # AppleEpf::Finder.find_incremental(Date.parse('20140311'), 'popularity')
    # => "https://feeds.itunes.apple.com/feeds/epf/v3/full/20140305/incremental/20140311/popularity20140311.tbz"
    def find_incremental(date, filename)
      all_weeks = get_weekly_folders_from_full_url
      potential_dates = detect_closest_weeks_for_date(all_weeks, date)
      founded_url = nil
      potential_dates.reverse.each do |potential|
        found = week_include_date?(potential, date)
        if found
          _founded_url = (ITUNES_INCREMENTAL_URL % potential) + date_to_epf_format(date) +
            "/" + "#{filename}#{date_to_epf_format(date)}.tbz"
          founded_url = _founded_url if file_exists?(_founded_url)
          break if founded_url
        end
      end

      founded_url
    end

    #daily_date is Date object
    def week_include_date?(week_date, daily_date)
      dates = get_daily_incremental_folders_within_week_url(week_date)
      dates.detect{|d| Date.parse(d) == daily_date}
    end

    #date is Date object
    def detect_closest_weeks_for_date(all_weeks, date)
      date_range = ((date - 16)..(date + 16)).to_a
      all_weeks.select{|d| date_range.include?(Date.parse(d))}
    end

    def get_daily_incremental_folders_within_week_url(week_folder)
      url = ITUNES_INCREMENTAL_URL % week_folder
      get_folders_from_url(url)
    end

    def get_weekly_folders_from_full_url
      get_folders_from_url(ITUNES_FULL_URL)
    end


    def get_folders_from_url(url)
      uri = URI(url)

      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth(AppleEpf.apple_id, AppleEpf.apple_password)

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
        http.request(req)
      }

      body = res.body
      avaliable_dates =  Nokogiri::HTML(body).xpath("//td/a").map(&:text).select{|s| s[0..7] =~ /\d{8}/}.map{|s| s.chomp("/")}
      avaliable_dates
    end


    def date_to_epf_format(date)
      date.strftime("%Y%m%d")
    end

    def file_exists?(full_url)

      uri = URI.parse(full_url)

      request = Net::HTTP::Head.new(full_url)
      request.basic_auth(AppleEpf.apple_id, AppleEpf.apple_password)

      r = Net::HTTP.new(uri.host, uri.port)
      r.use_ssl = true
      response = r.start { |http| http.request(request) }

      raise AppleEpf::BadCredentialsError.new('Bad credentials') if response.code == "401"

      response.code == "200"
    end

  end
end
