Gem::Specification.new do |s|

  s.authors = ["Mickael Riga"]
  s.email = ["mig@mypeplum.com"]
  s.homepage = "https://github.com/mig-hub/web-utils"
  s.licenses = ['MIT']

  s.name = 'web-utils'
  s.version = '0.0.1'
  s.summary = "Web Utils"
  s.description = "Useful web-related helper methods for models, views or controllers."

  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split("\n").sort
  s.test_files = s.files.grep(/^test\//)
  s.require_paths = ['lib']
  s.add_dependency('rack', '~> 0')

end

