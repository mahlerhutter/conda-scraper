require 'test_helper'

class ScrapeCondaJobTest < ActiveJob::TestCase
  test "projects are parsed" do
    (1..3).each do |i|
      data = File.read(Rails.root+"test/scrape-data/conda/page-#{i}.html")
      projects = CondaSectionParser.parse data
      assert (projects.count > 0)
    end
  end

  test "empty page is not parsed" do
    data = File.read(Rails.root+"test/scrape-data/conda/page-4.html")
    projects = CondaSectionParser.parse data
    assert (projects.count == 0)
  end
end
