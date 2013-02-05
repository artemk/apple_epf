$LOAD_PATH << "." unless $LOAD_PATH.include?(".")
require 'logger'
require 'tempfile'

begin
  require "rubygems"
  require "bundler"

  if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.5")
    raise RuntimeError, "Your bundler version is too old." +
     "Run `gem install bundler` to upgrade."
  end

  # Set up load paths for all bundled gems
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run \`bundle install\`?"
end

Bundler.require

require 'webmock/rspec'
require 'timecop'

RSpec.configure do |config|
  config.before(:each) do
    AppleEpf.configure do |c|
      c.log_to_console = true
    end

    WebMock.disable_net_connect!
  end
  config.filter_run :wip => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

