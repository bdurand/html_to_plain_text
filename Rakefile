require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'bump/tasks'

desc 'Default: run unit tests.'
task :default => :test

desc 'Run the unit tests'
RSpec::Core::RakeTask.new(:test)
