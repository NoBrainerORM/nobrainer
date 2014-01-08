# encoding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nobrainer"
  s.version     = '0.11.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nicolas Viennot"]
  s.email       = ["nicolas@viennot.biz"]
  s.homepage    = "http://github.com/nviennot/nobrainer"
  s.summary     = "ORM for RethinkDB"
  s.description = "ORM for RethinkDB"
  s.license     = 'MIT'

  s.add_dependency "rethinkdb",   "~> 1.11.0.1"
  s.add_dependency "activemodel", ">= 3.2.0", "< 5"
  s.add_dependency "middleware",  "~> 0.1.0"

  s.files        = Dir["lib/**/*"] + ['README.md'] + ['LICENSE.md']
  s.require_path = 'lib'
  s.has_rdoc     = false
end
