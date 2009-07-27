require "path-to/described_routes"

# bootstrap a path-to client from the test_rails_app provided in described_routes
app = PathTo::DescribedRoutes::Application.discover("http://localhost:3000/users")
#=> <PathTo::DescribedRoutes::Application>

# get user 'dojo'
puts app.users['dojo'].get
#=> '<html>...</html>

# get a JSON representation of the recent articles of user 'dojo'
puts app.users['dojo'].articles.recent['format' => 'json'].get
#=> [...]
