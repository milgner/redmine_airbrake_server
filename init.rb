require 'redmine'
require_dependency 'airbrake_server/hooks'

Redmine::Plugin.register :redmine_airbrake_server do
  name 'Redmine Airbrake Server plugin'
  author 'Marcus Ilgner'
  description 'Allows Redmine to receive error notifications Airbrake-style'
  version '0.3'
  url 'https://github.com/milgner/redmine_airbrake_server'
  author_url 'http://marcusilgner.com'

  requires_redmine_plugin :project_settings_hook_plugin, :version_or_higher => '0.0.1'
end

