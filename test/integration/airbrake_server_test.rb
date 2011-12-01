require File.expand_path('../../test_helper', __FILE__)

class AirbrakeServerTest < ActionController::IntegrationTest
  NOTIFIER_URL = '/notifier_api/v2/notices/'
  
  fixtures :projects, :versions, :users, :trackers, :projects_trackers, :issue_statuses, :enabled_modules, :enumerations

  @@xml_notice_data = <<EOF
    <notifier>
      <name>Airbrake Notifier</name>
      <version>1.2.4</version>
      <url>http://airbrakeapp.com</url>
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
  
  @@xml_notice_data_full = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <notice version=\"2.0\">
    <api-key>--- \n:project: ecookbook\n:priority: 5\n:assigned_to: jsmith\n:fixed_version_id: 3\n:tracker: Bug\n:login: jsmith\n:category: Development\n:api_key: \"1234567890\"\n:reopen_strategy: production\n</api-key>" + @@xml_notice_data

  @@xml_notice_data_slim = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <notice version=\"2.0\">
      <api-key>--- \n:api_key: \"1234567890\"\n:project: ecookbook\n</api-key>" + @@xml_notice_data

  def setup
    Setting['mail_handler_api_key'] = "1234567890"
  end
  
  def test_routing
     assert_routing(
       {:method => :post, :path => '/notifier_api/v2/notices'},
       :controller => 'airbrake', :action => 'index'
     )
  end
   
  def test_create_new_issues
    i = post_and_find_issue(@@xml_notice_data_full)
    assert_equal '[Airbrake] RuntimeError in /testapp/app/models/user.rb:53', i.subject
    assert i.description.include?("RuntimeError: I've made a huge mistake")
    assert i.description.include?("/testapp/app/controllers/users_controller.rb")
    assert_equal "production", i.custom_value_for(IssueCustomField.find_by_name('Environment')).value
    assert_equal "1.0.0", i.custom_value_for(IssueCustomField.find_by_name('Version')).value
    assert_equal 'jsmith', i.author.login
    assert_equal 3, i.fixed_version_id
  end
  
  def test_with_local_settings
    AirbrakeServerProjectSettings.create(:project_id => 1,
                                :category_id => 1,
                                :fixed_version_id => 3,
                                :tracker_id => 1,
                                :author_id => 2,
                                :assign_to_id => 3,
                                :priority_id => 5,
                                :reopen_strategy => 'production')
    s = AirbrakeServerProjectSettings.find_by_project_id(1)
    assert_equal 1, s.category_id
    i = post_and_find_issue(@@xml_notice_data_slim)
    assert_equal(1, i.category_id)
    assert_equal(3, i.fixed_version_id)
    assert_equal(2, i.author_id)
    assert_equal(5, i.priority_id)
    assert_equal(3, i.assigned_to_id)
  end
  
  def test_increase_occurrences_for_existing_issues
    i = post_and_find_issue(@@xml_notice_data_full)
    assert_equal "1", i.custom_value_for(IssueCustomField.find_by_name('# Occurrences').id).value
    i2 = post_and_find_issue(@@xml_notice_data_full)
    assert_equal i, i2
    assert_equal "2", i2.custom_value_for(IssueCustomField.find_by_name('# Occurrences').id).value
  end

  def test_reopen_journal
    i = post_and_find_issue(@@xml_notice_data_full)
    i.status = IssueStatus.find(:first, :conditions => {:is_closed => true}, :order => 'position ASC')
    i.save
    assert_equal 0, i.journals.size
    i2 = post_and_find_issue(@@xml_notice_data_full)
    assert !i2.status.is_closed?
    assert_equal 1, i2.journals.size
  end

  def test_settings_page
    log_user("admin", "admin")
    get(url_for(:controller => 'projects', :action => "settings", :id => 'ecookbook', :tab => 'airbrake_server'))
    assert_response :success
  end
  
  private

  #def filtered_backtrace
  #  if exception = @response.template.instance_variable_get(:@exception)
  #    filter_backtrace(exception.backtrace).join("\n")
  #  end
  #end
  
  def post_and_find_issue(issue_data)
    post(NOTIFIER_URL, issue_data, {"Content-type" => "text/xml"})
    assert_response :success #, filtered_backtrace
    Issue.find :last
  end
end
