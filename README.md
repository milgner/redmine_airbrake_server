# Hoptoad Server v2 for Redmine

An implementation of the Hoptoad protocol for Redmine which automatically creates issues from notices submitted via Hoptoad notifiers.
Inspired by and loosely based on the [v1 Hoptoad server by Jan Schulz-Hofen](https://github.com/yeah/redmine_hoptoad_server)


## Installation

Install the hpricot gem, then install the plugin into Redmine [as usual](http://www.redmine.org/projects/redmine/wiki/Plugins).
Now go to _Administration -> Settings -> Incoming emails_ and, if neccessary, check the box _Enable WS for incoming emails_ and generate and API key. This is the key you will need in the next step to configure your notifier.


## Client-Configuration

For a rails application, just setup the Hoptoad notifier as usual, then modify `config/initializers/hoptoad.rb` according to your using this template:

	HoptoadNotifier.configure do |config|
	  config.api_key = {:project => 'redmine_project_identifier',    # the identifier you specified for your project in Redmine
	                    :tracker => 'Bug',                           # the name of your Tracker of choice in Redmine
	                    :api_key => 'my_redmine_api_key',            # the key you generated before in Redmine (NOT YOUR HOPTOAD API KEY!)
	                    :category => 'Development',                  # the name of a ticket category (optional.)
	                    :assigned_to => 'admin',                     # the login of a user the ticket should get assigned to by default (optional.)
	                    :priority => 5                               # the default priority (use a number, not a name. optional.)
	                   }.to_yaml
	  config.host = 'my_redmine_host.com'                            # the hostname your Redmine runs at
	  config.port = 443                                              # the port your Redmine runs at
	  config.secure = true                                           # sends data to your server via SSL (optional.)
	end

That's it. You may `rake hoptoad:test` to generate a test issue.
If it doesn't work, check your logs and configuration, then [submit an issue on Github](https://github.com/milgner/redmine_hoptoad_server_v2/issues)


## License

This plugin is licensed under the [Apache license 2.0](http://www.apache.org/licenses/LICENSE-2.0.html)


## Author

Written by [Marcus Ilgner](mailto:mail@marcusilgner.com)