ActionController::Routing::Routes.draw do |map|
  map.connect '/notifier_api/v2/notices/', :controller => 'hoptoad', :action => 'index', :conditions => { :method => :post }
end
