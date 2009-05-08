# Adapted from jnunemaker/httparty/examples/delicious.rb to demonstrate path-to's metadata-driven REST client API capability
# For more information see http://positiveincline.com/?tag=path-to

require 'path-to/described_routes'
require 'pp'

# read $HOME/.delicious (YAML format):
#   username: <username>
#   password: <password>
config = YAML::load(File.read(File.join(ENV['HOME'], '.delicious')))

# Create a basic delicious API object driven by the metadata in delicious.yaml.
# This defines these resources (of which the last two are equivalent):
#
#   delicious.posts
#   delicious.posts.recent
#   delicious.recent_posts
#
# delicious.posts may take (as delicious.posts(params) or delicious.post[params])
#
#   tag (optional). Filter by this tag.
#   dt  (optional). Filter by this date (CCYY-MM-DDThh:mm:ssZ).
#   url (optional). Filter by this url.
#
# delicious.recent_posts may take
#
#   tag   (optional). Filter by this tag.
#   count (optional). Number of items to retrieve (Default:15, Maximum:100)
#
# Same for delicious.posts.recent, or it can inherit the tag parameter from posts, as in
#
#   pp delicious.posts['tag' => 'ruby'].recent
#
delicious = PathTo::DescribedRoutes::Application.new(
              :yaml => File.read(File.join(File.dirname(__FILE__), 'delicious.yaml')),
              :http_options => {
                  :basic_auth => {
                      :username => config['username'],
                      :password => config['password']}})

pp delicious.posts['tag' => 'ruby'].get
pp delicious.posts['tag' => 'ruby'].recent['count' => '5'].get
delicious.recent_posts.get['posts']['post'].each { |post| puts post['href'] }
