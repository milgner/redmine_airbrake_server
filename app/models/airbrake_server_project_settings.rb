class AirbrakeServerProjectSettings < ActiveRecord::Base
  belongs_to :project
  
  belongs_to :tracker
  belongs_to :category, :class_name => 'IssueCategory'
  belongs_to :fixed_version, :class_name => 'Version'
  
  belongs_to :author, :class_name => 'User'
  belongs_to :assign_to, :class_name => 'User'
  belongs_to :priority, :class_name => 'IssuePriority'

  def self.find_or_create(project)
    settings = find_by_project_id(project.id)
    unless settings
      settings = AirbrakeServerProjectSettings.new
      settings.project = project
      settings.author = User.anonymous
      settings.fixed_version = project.versions.last
      settings.category = project.issue_categories.first
      settings.tracker = project.trackers.first
      settings.save
    end
    settings
  end
end