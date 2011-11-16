require 'hpricot'

class AirbrakeController < ApplicationController
  skip_before_filter :check_if_login_required
  before_filter :find_or_create_custom_fields

  unloadable
  
  def index
    redirect_to root_path unless request.post? && !params[:notice].nil?
    @notice = params[:notice]
    if (@notice['version'] != "2.0")
      logger.warn("Expected Airbrake notice version 2.0 but got #{@notice['version']}. You should consider filing an enhancement request or updating the plugin.")
    end

    restore_var_elements(request.body)
    
    redmine_params = YAML.load(@notice['api_key'])
    raise ArgumentError.new("Invalid API key #{Setting.mail_handler_api_key} != #{redmine_params[:api_key]}") unless Setting.mail_handler_api_key == redmine_params[:api_key]

    read_settings(redmine_params)

    subject = build_subject
    @issue = Issue.find_by_subject_and_project_id_and_tracker_id(subject, @settings[:project].id, @settings[:tracker].id)
    
    if @issue.nil?
      create_new_issue
    else
      update_existing_issue
    end
    
    render :layout => false
  end
  
  private

  # The automagic XML parsing by Rails ignores the text elements
  # This method replaces the garbled elements with new hashes
  def restore_var_elements(original_xml)
    return if @notice['request'].nil?
    
    doc = Hpricot::XML(request.body)
    
    unless @notice['request']['params'].nil?
      request_params = convert_var_elements(doc/'/notice/request/params/var')
      request_params.delete('action') # already known
      request_params.delete('controller') # already known    
      @notice['request']['params'] = request_params
    end
    
    unless @notice['request']['cgi_data'].nil?
      cgi_data = convert_var_elements(doc/'notice/request/cgi-data/var')
      @notice['request']['cgi_data'] = cgi_data
    end
    
    unless @notice['request']['session'].nil?
      session_vars = convert_var_elements(doc/'/notice/request/session/var')
      @notice['request']['session'] = session_vars
    end
  end
  
  def convert_var_elements(elements)
    result = {}
    elements.each do |elem|
      result[elem.attributes['key']] = elem.inner_text
    end
    result
  end
  
  def read_settings(params)
    @settings = {}
    @settings[:project] = Project.find_by_identifier(params[:project]) or raise ArgumentError.new("invalid project #{params[:project]}")
    @settings[:tracker] = @settings[:project].trackers.find_by_name(params[:tracker]) or raise ArgumentError.new("tracker #{params[:tracker]} not found in project #{params[:project]}")
    check_custom_field_assignments
    # these are optional
    @settings[:author] = params[:login].nil? ? User.anonymous : (User.find_by_login(params[:login])||User.anonymous)
    @settings[:reopen_strategy] = params[:reopen] || 'always'
    @settings[:category] = IssueCategory.find_by_name(params[:category]) unless params[:category].blank?
    @settings[:assigned_to] = User.find_by_login(params[:assigned_to]) unless params[:assigned_to].blank?
    @settings[:priority] = params[:priority] unless params[:priority].blank?
    @settings[:fixed_version] = params[:fixed_version] unless params[:fixed_version].blank?
  end
  
  def create_new_issue
    @issue = Issue.new
    @issue.author = @settings[:author]
    @issue.subject = build_subject
    @issue.tracker = @settings[:tracker]
    @issue.project = @settings[:project]
    @issue.category = @settings[:category]
    @issue.fixed_version_id = @settings[:fixed_version]
    @issue.assigned_to = @settings[:assigned_to]
    @issue.priority_id = @settings[:priority] unless @settings[:priority].nil?
    @issue.description = render_to_string(:partial => 'issue_description')
    @issue.status = issue_status_open
    @issue.custom_values.build(:custom_field => @occurrences_field, :value => '1')
    @issue.custom_values.build(:custom_field => @environment_field, :value => @notice['server_environment']['environment_name'])
    @issue.custom_values.build(:custom_field => @version_field, :value => @notice['server_environment']['app_version']) unless @notice['server_environment']['app_version'].nil?
    @issue.save!
  end
  
  def check_custom_field_assignments
    [@occurrences_field, @environment_field, @version_field].each do |field|
      @settings[:project].issue_custom_fields << field unless @settings[:project].issue_custom_fields.include?(field)
      @settings[:tracker].custom_fields << field unless @settings[:tracker].custom_fields.include?(field)
    end
  end
  
  def update_existing_issue
    environment_name = @notice['server_environment']['environment_name']
    if (['always', environment_name].include?(@settings[:reopen_strategy]))
      @issue.status = issue_status_open if @issue.status.is_closed?
      @issue.init_journal(@settings[:author], "h4. Issue reopened after occurring again in #{environment_name} environment")
    end
    number_occurrences = @issue.custom_value_for(@occurrences_field.id).value
    @issue.custom_field_values = { @occurrences_field.id => (number_occurrences.to_i+1).to_s }
    @issue.save!
  end
  
  def issue_status_open
    IssueStatus.find(:first, :conditions => {:is_default => true}, :order => 'position ASC')
  end
   
  def build_subject
    error_class = @notice['error']['class']
    # if there's only one line, it gets parsed into a hash instead of an array
    if @notice['error']['backtrace']['line'].is_a? Hash
      file = @notice['error']['backtrace']['line']['file']
      line = @notice['error']['backtrace']['line']['number']
    else
      file = @notice['error']['backtrace']['line'].first()['file']
      line = @notice['error']['backtrace']['line'].first()['number']
    end
    "[Airbrake] #{error_class} in #{file}:#{line}"[0..254]
  end
  
  def find_or_create_custom_fields
    @occurrences_field = IssueCustomField.find_or_initialize_by_name('# Occurrences')
    if @occurrences_field.new_record?
      @occurrences_field.attributes = {:field_format => 'int', :default_value => '1', :is_filter => true}
      @occurrences_field.save(false)
    end
    
    @environment_field = IssueCustomField.find_or_initialize_by_name('Environment')
    if @environment_field.new_record?
      @environment_field.attributes = {:field_format => 'string', :default_value => 'production', :is_filter => true}
      @environment_field.save(false)
    end
    
    @version_field = IssueCustomField.find_or_initialize_by_name('Version')
    if @version_field.new_record?
      @version_field.attributes = {:field_format => 'string', :default_value => '', :is_filter => true}
      @version_field.save(false)
    end
  end
end
