RedmineApp::Application.routes.draw do
  match 'projects/:id/settings/airbrake_server', :to => "airbrake_server_project_settings#update"
  post '/notifier_api/v2/notices/' => 'airbrake#index'
end
