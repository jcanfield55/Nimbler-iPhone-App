# RestKit Sinatra Testing Server
# Place at Tests/server.rb and run with `ruby Tests/Server.rb` before executing the test suite within Xcode

require 'sinatra'

configure do
  set :logging, true
  set :dump_errors, true
end

def render_fixture(filename)
  send_file filename
end

get '/TPServer/ws/gtfs/rawdata' do
   render_fixture('gtfs_rawdata_calendar.json')
end

# Creates a route that will match /TPServer/ws/livefeeds/bylegs
get '/TPServer/ws/livefeeds/bylegs' do
  render_fixture('livefeeds_bylegs1.json')
end

# Return a 503 response to test error conditions
get '/offline' do
  status 503
end

# Simulate a JSON error
get '/error' do
  status 400
  content_type 'application/json'
  "{f36a311cba6c29ba4c54f0b8c76e6cb733c01e65quot;errorf36a311cba6c29ba4c54f0b8c76e6cb733c01e65quot;: f36a311cba6c29ba4c54f0b8c76e6cb733c01e65quot;An error occurred!!f36a311cba6c29ba4c54f0b8c76e6cb733c01e65quot;}"
end