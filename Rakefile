require 'rubygems'
require 'bundler'
Bundler.require

task :parallel_rspec do
  require "parallel_tests"
  ParallelTests::CLI.new.run %w(--type rspec -n4)
end

task :default => :parallel_rspec
