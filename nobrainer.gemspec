# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = 'nobrainer'
  s.version     = '0.44.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Viennot']
  s.email       = ['nicolas@viennot.biz']
  s.homepage    = 'http://nobrainer.io'
  s.summary     = 'A Ruby ORM for RethinkDB'
  s.description = 'The goal of NoBrainer is to provide a similar interface ' \
                  'compared to ActiveRecord and Mongoid to build data models ' \
                  'on top of RethinkDB while providing precise semantics.'
  s.license     = 'LGPL-3.0-only'

  s.required_ruby_version = ">= #{ENV.fetch('EARTHLY_RUBY_VERSION', '1.9.0')}"

  s.metadata['allowed_push_host'] = 'https://rubygems.org'
  s.metadata['homepage_uri'] = s.homepage
  s.metadata['source_code_uri'] = 'https://github.com/NoBrainerORM/nobrainer'
  s.metadata['changelog_uri'] = 'https://github.com/NoBrainerORM/nobrainer/blob/master/CHANGELOG.md'

  s.add_dependency 'activemodel', '>= 4.1.0', '< 8'
  s.add_dependency 'activesupport', '>= 4.1.0', '< 8'
  s.add_dependency 'middleware', '~> 0.1.0'
  s.add_dependency 'rethinkdb', '>= 2.3.0', '< 2.5'
  s.add_dependency 'symbol_decoration', '~> 1.1'

  s.files        = Dir['lib/**/*'] + ['README.md'] + ['LICENSE'] + ['CHANGELOG.md']
  s.require_path = 'lib'
end
