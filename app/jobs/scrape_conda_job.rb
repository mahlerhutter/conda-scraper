require "uri"
require "pp"
require "net/http"
require "nokogiri"


class ScrapeCondaJob < ActiveJob::Base
  queue_as :default

  URL_PATTERN = "https://www.conda.eu/startup/?list_page=%d&action=ajax_list_load&type=projects&wrapper_style=items_full&filter_region_slug=eu&filter_company_id=&filter_status=&filter_orderby=menu_order&list_posts_per_page=10"

  def perform(*args)
    uri = URL_PATTERN % 1
    data = fetch_uri uri
    #data = open("sample-scrape.html")

    doc = Nokogiri::HTML(data, nil, 'utf-8')
    found_projects = []

    doc.xpath('//section').each do |section|
      project = {}
      project[:title] = section.at_css('.en_mdl_project_tile__title_wrapper h3').content
      location = section.at_css('span.en_icon.en_icon--pin')

      project[:url] = "https://www.conda.eu" + \
        section.at_css('a.en_mdl_project_tile__inner').attribute('href').content

      project[:location] = location.content unless location.nil?
      has_started = true

      # IN KÜRZE badge
      if section.css('.en_mdl_project_tile__eyecatcher .en_eyecatcher__word').count == 2
        has_started = false

        fundraising_values = section.css('.en_mdl_project_tile__graph .en_data__item .en_data__value')
        unless fundraising_values.empty? then
          project[:funding_threshold] = fundraising_values[0].content.gsub(/[^0-9]/, '')
          project[:funding_limit]     = fundraising_values[1].content.gsub(/[^0-9]/, '')
        end
      end

      graph = section.at_css('div.js_only.en_graph') if has_started
      if not graph.nil?
        project[:funding_threshold] = graph.attribute('data-en-graph-investment-min').content
        project[:funding_limit]     = graph.attribute('data-en-graph-investment-max').content
        project[:funding_current]   = graph.attribute('data-en-graph-investment-current').content
        project[:investors_count]   = graph.attribute('data-en-graph-number-investors').content
      end

      found_projects << project
    end
    found_projects
  end

  private
  def fetch_uri uri_str
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
      body = resp.body
    end

    body
  end

end
