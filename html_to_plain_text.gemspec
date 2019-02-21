Gem::Specification.new do |s|
  s.name = 'html_to_plain_text'
  s.version = File.read(File.expand_path("../VERSION", __FILE__)).strip
  s.summary = "A simple library for converting HTML into plain text."
  s.description = "A simple library for converting HTML into an approximation in plain text."

  s.authors = ['Brian Durand']
  s.email = ['bdurand@embellishedvisions.com']
  s.homepage = "https://github.com/bdurand/html_to_plain_text"

  s.files = ['README.rdoc', 'VERSION', 'Rakefile', 'MIT_LICENSE'] +  Dir.glob('lib/**/*')

  s.rdoc_options = ["--charset=UTF-8", "--main", "README.rdoc"]
  s.extra_rdoc_files = ["README.rdoc"]

  s.add_dependency "nokogiri", ">=1.4.0"
  s.add_development_dependency "rspec", ">2.6.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "bump"
end
