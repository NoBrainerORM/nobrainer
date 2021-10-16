# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = 'nobrainer'
  s.version     = '0.40.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Viennot']
  s.email       = ['nicolas@viennot.biz']
  s.homepage    = 'http://nobrainer.io'
  s.summary     = 'A Ruby ORM for RethinkDB'
  s.description = 'The goal of NoBrainer is to provide a similar interface ' \
                  'compared to ActiveRecord and Mongoid to build data models ' \
                  'on top of RethinkDB while providing precise semantics.'
  s.license     = 'LGPLv3'

  s.add_dependency 'activemodel', '>= 4.1.0'
  s.add_dependency 'activesupport', '>= 4.1.0'
  s.add_dependency 'middleware', '~> 0.1.0'
  s.add_dependency 'rethinkdb', '>= 2.3.0'
  s.add_dependency 'symbol_decoration', '~> 1.1'

  s.files        = Dir['lib/**/*'] + ['README.md'] + ['LICENSE'] + ['CHANGELOG.md']
  s.require_path = 'lib'

  s.required_ruby_version = '>= 1.9.0'
end
