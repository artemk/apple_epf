$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "apple_epf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "apple_epf"
  s.version     = AppleEpf::VERSION
  s.authors     = ["Artem Kramarenko"]
  s.email       = ["me@artemk.name"]
  s.summary     = "Downloader, Extractor and Parser for Apple Epf Affiliate files"
  s.description = "Downloader, Extractor and Parser for Apple Epf Affiliate files"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_development_dependency "rspec", "~> 2.12"
  s.add_development_dependency "rails", "~> 3.2.3"
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rb-fsevent', '~> 0.9.1'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'thin'

  s.add_dependency "curb"
  s.add_dependency 'chronic', '~> 0.10.0'
  s.add_dependency "nokogiri", ">= 1.5.6"

  #note you will also need aria2 command line to use aria downlaoder
end
