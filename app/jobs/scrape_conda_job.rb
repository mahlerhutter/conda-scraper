require "uri"
require "pp"
require "net/http"
require "nokogiri"


class ScrapeCondaJob < ActiveJob::Base
  queue_as :default

  URL_PATTERN = "https://www.conda.eu/startup/?list_page=%d&action=ajax_list_load&type=projects&wrapper_style=items_full&filter_region_slug=eu&filter_company_id=&filter_status=&filter_orderby=menu_order&list_posts_per_page=10"

  def perform(*args)
    page = 1
    status = {
      :status => "ok"
    }
    found_projects_count = 0

    begin
    while true do
      data = fetch_uri(URL_PATTERN % page)

      if data.nil? then raise "empty data" end

      found_projects = CondaSectionParser.parse data

      break if found_projects.empty?

      page = page.succ
      found_projects.each do |project_data|
        project = Project.find_or_create_by(
          source: "conda.eu",
          title: project_data[:title]
        )

        project.update(project_data)

        begin
        if not project.save then
          pp project.errors
          break
        else
          found_projects_count = found_projects_count.succ
        end
        rescue ActiveRecord::RecordNotUnique
          #break
        end
      end

      page = page.succ
    end

    status[:found_projects] = found_projects_count

    rescue Error => e
      status[:status] = "error"
      status[:error]  = e.message
      return status
    end

    status
  end



  private

  def fetch_uri uri_str
    p "fetching #{uri_str}"
    uri = URI.parse(uri_str)
    #base_uri = "#{uri.scheme}://#{uri.host}#{uri.path}"

    body = nil
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
      req = Net::HTTP::Get.new(uri)

      # mimic my FF
      req['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64; rv:37.0) Gecko/20100101 Firefox/37.0'
      req['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      req['Accept-Language'] = 'en-US,en;q=0.5'
      req['X-Requested-With'] = 'XMLHttpRequest'
      req['Referer'] = 'https://www.conda.eu/startup/'

      resp = http.request req

      if resp.code != "200"
        raise "fetch error"
      end

      body = resp.body
    end

    body
  end

end
