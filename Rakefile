require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'RVM likes to call it tests'
task :tests => :test

begin
  require 'rspec'
  require 'rspec/core/rake_task'
  desc 'Run the unit tests'
  RSpec::Core::RakeTask.new(:test)
rescue LoadError
  task :test do
    STDERR.puts "You must have rspec 2.0 installed to run the tests"
  end
end

desc 'Generate rdoc.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options << '--title' << 'HTML To Plain Text' << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec_file = File.expand_path('../html_to_plain_text.gemspec', __FILE__)
if File.exist?(spec_file)
  spec = eval(File.read(spec_file))

  Rake::GemPackageTask.new(spec) do |p|
    p.gem_spec = spec
  end

  desc "Release to rubygems.org"
  task :release => :package do
    require 'rake/gemcutter'
    Rake::Gemcutter::Tasks.new(spec).define
    Rake::Task['gem:push'].invoke
  end
end
