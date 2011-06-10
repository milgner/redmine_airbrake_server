class HoptoadController < ApplicationController
  unloadable
  
  def index
    redirect_to '/' unless request.post? && !params[:notice].empty?
    notice = params[:notice]
    redmine_params = YAML.load(notice['api_key'])
    raise ArgumentError.new("invalid API key") unless Setting.mail_handler_api_key == redmine_params[:api_key]

    settings = read_settings(redmine_params)

    subject = build_subject(notice)    
    issue = Issue.find_by_subject_and_project_id_and_tracker_id(subject, settings[:project].id, settings[:tracker].id)
    
    if issue.nil?
      create_new_issue(notice, settings)
    else
      update_existing_issue(issue, notice)
    end
    
    render :text => 'OK'
  end
  
  private

  def read_settings(params)
    settings = {}
    settings[:project] = Project.find_by_identifier(params[:project]) or raise ArgumentError.new("invalid project #{params[:project]}")
    settings[:tracker] = settings[:project].trackers.find_by_name(params[:tracker]) or raise ArgumentError.new("tracker #{params[:tracker]} not found in project #{params[:project]}")

    # these are optional
    settings[:category] = IssueCategory.find_by_name(params[:category]) unless params[:category].blank?
    settings[:assigned_to] = User.find_by_login(params[:assigned_to]) unless params[:assigned_to].blank?
    settings[:priority] = params[:priority] unless params[:priority].blank?
    settings
  end
  
  def create_new_issue(notice, settings)
    issue = Issue.new
    issue.author = User.anonymous
    issue.subject = build_subject(notice)
    issue.tracker = settings[:tracker]
    issue.project = settings[:project]
    issue.category = settings[:category]
    issue.assigned_to = settings[:assigned_to]
    issue.priority_id = settings[:priority]
    issue.description = build_description(notice)
    issue.status = issue_status_open
    issue.save!
  end
  
  def update_existing_issue(issue, notice)
    issue.status = issue_status_open
  end
  
  def issue_status_open
    IssueStatus.find(:first, :conditions => {:is_default => true}, :order => 'position ASC')
  end
  
  def build_description(notice)
    error = "The Hoptoad notifier reported an error: #{notice['error']['message']}\n\n"
    error << "Backtrace:\n\nbq. "
    notice['error']['backtrace']['line'].each do |element|
      error << "#{element['method']} in source:#{element['file']}#L#{element['number']}\n"
    end
    error << "\n"
  end
  
  def short_error_info(notice)
    info = {}
    # logger.debug("Notice backtrace: #{notice['error']['backtrace'].inspect}")
    info[:error_class] = notice['error']['class']
    info[:file] = notice['error']['backtrace']['line'].first()['file']
    info[:line] = notice['error']['backtrace']['line'].first()['number']
    info
  end
  
  def build_subject(notice)
    error_info = short_error_info(notice)
    "[Hoptoad] #{error_info[:error_class]} in #{error_info[:file]}:#{error_info[:line]}"
  end
end