require File.expand_path('../../test_helper', __FILE__)

class HoptoadServerTest < ActionController::IntegrationTest
  NOTIFIER_URL = '/notifier_api/v2/notices/'
  
  fixtures :projects, :versions, :users, :trackers, :projects_trackers, :issue_statuses, :enabled_modules, :enumerations

  @@xml_notice_data = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<notice version="2.0">
  <api-key>--- \n:assigned_to: marcus\n:api_key: "1234567890"\n:tracker: Bug\n:project: ecookbook\n:priority: 5\n:category: Development\n</api-key>
  <notifier>
    <name>Hoptoad Notifier</name>
    <version>1.2.4</version>
    <url>http://hoptoadapp.com</url>
  </notifier>
  <error>
    <class>RuntimeError</class>
    <message>RuntimeError: I've made a huge mistake</message>
    <backtrace>
      <line method="public" file="/testapp/app/models/user.rb" number="53"/>
      <line method="index" file="/testapp/app/controllers/users_controller.rb" number="14"/>
    </backtrace>
  </error>
  <request>
    <url>http://example.com</url>
    <component/>
    <action/>
    <cgi-data>
      <var key="SERVER_NAME">example.org</var>
      <var key="HTTP_USER_AGENT">Mozilla</var>
    </cgi-data>
  </request>
  <server-environment>
    <project-root>/testapp</project-root>
    <environment-name>production</environment-name>
    <app-version>1.0.0</app-version>
  </server-environment>
</notice>
EOF

  def setup
    Setting['mail_handler_api_key'] = "1234567890"
  end
  
  def test_routing
     assert_routing(
       {:method => :post, :path => '/notifier_api/v2/notices'},
       :controller => 'hoptoad', :action => 'index'
     )
  end
   
  def test_create_new_issues
    i = post_and_find_issue
    assert_equal '[Hoptoad] RuntimeError in /testapp/app/models/user.rb:53', i.subject
    assert i.description.include?("RuntimeError: I've made a huge mistake")
    assert i.description.include?("/testapp/app/controllers/users_controller.rb")
    assert_equal "production", i.custom_value_for(IssueCustomField.find_by_name('Environment')).value
    assert_equal "1.0.0", i.custom_value_for(IssueCustomField.find_by_name('Version')).value
  end
  
  def test_increase_occurrences_for_existing_issues
    i = post_and_find_issue
    assert_equal "1", i.custom_value_for(IssueCustomField.find_by_name('# Occurrences').id).value
    i2 = post_and_find_issue
    assert_equal i, i2
    assert_equal "2", i2.custom_value_for(IssueCustomField.find_by_name('# Occurrences').id).value
  end

  private

  def post_and_find_issue
    post(NOTIFIER_URL, @@xml_notice_data, {"Content-type" => "text/xml"})
    assert_response :success
    Issue.find :last
  end
end
