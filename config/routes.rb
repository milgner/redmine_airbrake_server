ActionController::Routing::Routes.draw do |map|
  map.connect '/notifier_api/v2/notices/', :controller => 'airbrake', :action => 'index', :conditions => { :method => :post }
end
