module FixtureHelper
  def apple_epf_dir
    File.expand_path("../../support/fixtures/itunes/epf/incremental", __FILE__)
  end

  def apple_epf_inc_filename(filename)
    File.expand_path("../../support/fixtures/itunes/epf/incremental/#{filename}", __FILE__)
  end

  def apple_epf_filename(filename)
    File.expand_path("../../support/fixtures/itunes/epf/#{filename}", __FILE__)
  end
end

RSpec.configure do |config|
  config.include FixtureHelper
end
