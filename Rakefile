%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
$:.push File.dirname(__FILE__) + '/lib'
require 'path-to'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('path-to', PathTo::VERSION) do |p|
  p.developer('Mike Burrows (asplake)', 'mjb@asplake.co.uk')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'PostInstall.txt' # TODO remove if post-install message not required
  p.rubyforge_name       = p.name
  p.url = 'http://positiveincline.com/?p=213'
  p.extra_deps         = [
    ['httparty','>= 0.4.2'],
    ['addressable','>= 2.1.0'],
    ['described_routes','>= 0.4.1']
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
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
