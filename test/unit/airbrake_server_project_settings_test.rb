class ActivityTest < ActiveSupport::TestCase
  fixtures :projects, :issue_categories, :versions, :users,
           :trackers, :projects_trackers, :issue_statuses, :enumerations
  
  def test_find_or_create
    p = Project.find(1)
    s = AirbrakeServerProjectSettings.find_or_create(p)
    assert_equal p, s.project
    assert_equal User.anonymous, s.author
    assert_equal p.versions.last, s.fixed_version
    assert_not_nil s.category
    assert_equal p.issue_categories.first, s.category
    assert_equal p.trackers.first, s.tracker
  end

end
