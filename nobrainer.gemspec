# encoding: utf-8
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'nobrainer'
  s.version     = '0.13.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Viennot']
  s.email       = ['nicolas@viennot.biz']
  s.homepage    = 'http://nobrainer.io'
  s.summary     = 'ORM for RethinkDB'
  s.description = 'ORM for RethinkDB'
  s.license     = 'LGPLv3'

  s.add_dependency 'rethinkdb',     '~> 1.11.0.2'
  s.add_dependency 'activesupport', '>= 4.0.0'
  s.add_dependency 'activemodel',   '>= 4.0.0'
  s.add_dependency 'middleware',    '~> 0.1.0'

  s.files        = Dir['lib/**/*'] + ['README.md'] + ['LICENSE']
  s.require_path = 'lib'
  s.has_rdoc     = false

  s.required_ruby_version = '>= 1.9.0'
end
