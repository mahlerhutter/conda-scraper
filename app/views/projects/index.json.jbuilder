json.array!(@projects) do |project|
  json.extract! project, :id, :source, :title, :url, :location, :has_started, :funding_threshold, :funding_limit, :funding_current, :investors_count
  json.url project_url(project, format: :json)
end
