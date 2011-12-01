module AirbrakeServer
  module Hooks
    class ProjectSettingsTabHook < Redmine::Hook::ViewListener
      def helper_projects_settings_tabs(tabs)
        tabs[:tabs] << {:name => 'airbrake_server', :controller => 'airbrake_server_project_settings', :action => :show, :partial => 'airbrake_server_project_settings/show', :label => 'airbrake.heading'}
        tabs
      end
    end
  end
end
