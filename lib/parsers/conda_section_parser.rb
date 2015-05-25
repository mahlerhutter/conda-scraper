require 'nokogiri'
require 'pry'

class CondaSectionParser
  def self.parse data
    doc = Nokogiri::HTML(data, nil, 'utf-8')
    found_projects = []

    sections = doc.css('section.tilepane_item')

    if sections.nil?
      return found_projects
    end

    sections.each do |section|
      project = {}
      title = section.at_css('.en_mdl_project_tile__title_wrapper h3')
      project[:title] = title.content

      project[:url] = "https://www.conda.eu" + \
        section.at_css('a.en_mdl_project_tile__inner').attribute('href').content

      location = section.at_css('span.en_icon.en_icon--pin')
      project[:location] = location.content unless location.nil?

      has_started = true

      # IN KÜRZE badge
      if section.css('.en_mdl_project_tile__eyecatcher .en_eyecatcher__word').count == 2
        has_started = false
      end

      fundraising_values = section.css('.en_mdl_project_tile__graph .en_data__item .en_data__value')
      unless fundraising_values.empty? then
        project[:funding_threshold] = fundraising_values[0].content.gsub(/[^0-9]/, '')
        project[:funding_limit]     = fundraising_values[1].content.gsub(/[^0-9]/, '')
      end

      footer_fundraising_values = \
        section.css('.en_mdl_project_tile__footer .en_data .en_data__value')

      unless footer_fundraising_values.empty? then
        project[:funding_current] = footer_fundraising_values[1].content.gsub(/[^0-9]/, '').to_i
        project[:investors_count] = footer_fundraising_values[2].content.gsub(/[^0-9]/, '')

        #funding_percent = footer_fundraising_values[0].content.gsub(/[^0-9]/, '').to_f
        #project[:funding_threshold] = project[:funding_current]*100 / funding_percent
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
end
