desc "Scrape conda.eu projects"
task scrape_conda: [:environment] do
  status = ScrapeCondaJob.perform_now
  puts status.inspect
end

