require "bundler/gem_tasks"

require "rspec/core/rake_task"
require "standard/rake"

task :verify_release_branch do
  unless `git rev-parse --abbrev-ref HEAD`.chomp == "main"
    warn "Gem can only be released from the main branch"
    exit 1
  end
end

Rake::Task[:release].enhance([:verify_release_branch])

RSpec::Core::RakeTask.new(:spec)

task default: :spec
