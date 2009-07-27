%w[rubygems rake rake/clean fileutils newgem rubigen hoe].each { |f| require f }
$:.push File.dirname(__FILE__) + '/lib'
require 'path-to'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'path-to' do
  developer('Mike Burrows', 'mjb@asplake.co.uk')
  self.version = PathTo::VERSION
  self.readme_file          = "README.rdoc"
  self.summary = self.description              = paragraphs_of(self.readme_file, 1..1).join("\n\n")
  self.changes              = paragraphs_of("History.txt", 0..1).join("\n\n")
  self.rubyforge_name       = 'path-to'
  self.url = 'http://github.com/asplake/path-to/tree'
  self.extra_deps         = [
  ]
  self.extra_deps         = [
    ['httparty','>= 0.4.2'],
    ['addressable','>= 2.1.0'],
    ['described_routes','>= 0.6.0'],
    ['link_header','>= 0.0.4']
  ]
  self.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  self.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (rubyforge_name == name) ? rubyforge_name : "\#{rubyforge_name}/\#{name}"
  self.remote_rdoc_dir = File.join(path.gsub(/^#{rubyforge_name}\/?/,''), 'rdoc')
  self.rsync_args = '-av --delete --ignore-errors'
end

task :info do
  puts "version=#{PathTo::VERSION}"
  [:description, :summary, :changes, :author, :url].each do |attr|
    puts "#{attr}=#{$hoe.send(attr)}\n"
  end
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
