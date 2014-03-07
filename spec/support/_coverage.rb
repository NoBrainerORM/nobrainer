require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_group 'Document',     'lib/no_brainer/document'
  add_group 'Criteria',     'lib/no_brainer/criteria'
  add_group 'Query Runner', 'lib/no_brainer/query_runner'
end

pid = Process.pid
SimpleCov.at_exit do
  SimpleCov.result.format! if Process.pid == pid
end
