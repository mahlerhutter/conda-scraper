class Project < ActiveRecord::Base
  validates :title, presence: true
  validates :url, presence: true
  validates :source, inclusion: { in: ["conda.eu"] }

end
