# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "html_to_plain_text"
  spec.version = File.read(File.expand_path("../VERSION", __FILE__)).strip
  spec.authors = ["Brian Durand"]
  spec.email = ["bbdurand@gmail.com"]

  spec.summary = "A simple library for converting HTML into plain text."

  spec.homepage = "https://github.com/bdurand/html_to_plain_text"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  ignore_files = %w[
    .
    AGENTS.md
    Appraisals
    Gemfile
    Gemfile.lock
    Rakefile
    bin/
    gemfiles/
    spec/
    test_app/
  ]
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| ignore_files.any? { |path| f.start_with?(path) } }
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "nokogiri", ">=1.4.0"

  spec.add_development_dependency "bundler"
end
