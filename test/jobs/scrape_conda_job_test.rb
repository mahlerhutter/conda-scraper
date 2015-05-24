require 'test_helper'

class ScrapeCondaJobTest < ActiveJob::TestCase
  (1..4).each do |i|
    data = File.read(Rails.root+"tmp/scrape-data/page-#{i}.html")
    projects = ::CondaSectionParser.parse data
    pp projects
  end
end
