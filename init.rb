require 'redmine'

Redmine::Plugin.register :redmine_airbrake_server do
  name 'Redmine Airbrake Server plugin'
  author 'Marcus Ilgner'
  description 'Allows Redmine to receive error notifications Airbrake-style'
  version '0.0.2'
  url 'https://github.com/milgner/redmine_airbrake_server'
  author_url 'http://marcusilgner.com'
end

config.gem 'hpricot'
