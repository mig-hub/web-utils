# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$:.unshift lib
require 'web_utils'

Gem::Specification.new do |s|

  s.authors = ['Mickael Riga']
  s.email = ['mig@mypeplum.com']
  s.homepage = 'https://github.com/mig-hub/web-utils'
  s.licenses = ['MIT']

  s.name = 'web-utils'
  s.version = WebUtils::VERSION
  s.summary = 'Web Utils'
  s.description = 'Useful web-related helper methods for models, views or controllers.'

  s.platform = Gem::Platform::RUBY
  s.files = `git ls-files`.split("\n").sort
  s.test_files = s.files.grep(/^test\//)
  s.require_paths = ['lib']

  s.add_dependency 'rack', '>= 1.0'

  s.add_development_dependency 'bundler', '~> 1.13'
  s.add_development_dependency 'minitest', '~> 5.8'

end

