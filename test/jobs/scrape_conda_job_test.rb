require 'test_helper'

class ScrapeCondaJobTest < ActiveJob::TestCase

  projects = ScrapeCondaJob.perform_now
  pp projects
end
