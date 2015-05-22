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

    #lastfetched = Project

    begin
    while true do
      data = fetch_uri(URL_PATTERN % page)

      if data.nil? then raise "empty data" end

      File.open(Rails.root + "tmp/scrape-data/page-#{page}.html", 'wb') do |f|
        f.write(data)
        p "wrote to #{f.inspect}"
      end

      found_projects = parse data

      break if found_projects.empty?
      page = page.succ
      next

      found_projects.each do |project_data|
        project = Project.new(project_data)
        project.source = "conda.eu"

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
    status

    rescue Error => e
      status[:status] = "error"
      status[:error]  = e.message
    end

    status
  end



  private

  def parse fragment
    doc = Nokogiri::HTML(fragment, nil, 'utf-8')
    found_projects = []

    sections = doc.css('section')

    if sections.nil?
      pp fragment
      found_projects
    end

    pp sections

    sections.each do |section|
      project = {}
      title = section.at_css('.en_mdl_project_tile__title_wrapper h3')

      if title.nil? then
        pp "EMPTY TITLE"
        pp section
        next
      end

      project[:url] = "https://www.conda.eu" + \
        section.at_css('a.en_mdl_project_tile__inner').attribute('href').content

      location = section.at_css('span.en_icon.en_icon--pin')
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

      project[:has_started] = has_started

      found_projects << project
    end
    found_projects
  end

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
