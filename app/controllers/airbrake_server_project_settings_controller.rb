class AirbrakeServerProjectSettingsController < ApplicationController
  unloadable
  
  before_filter :load_project_and_settings
    
  def update
    @settings.update_attributes(params[:settings])
    redirect_to :controller => 'projects', :action => "settings", :id => @project, :tab => 'airbrake_server'
  end
  
  private
  
  def load_project_and_settings
    @project = Project.find(params[:project_id])
    @settings = AirbrakeServerProjectSettings.find_or_create(@project)
  end
end