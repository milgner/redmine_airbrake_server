ActionController::Routing::Routes.draw do |map|
  map.match '/notifier_api/v2/notices/', :controller => 'hoptoad'
end
