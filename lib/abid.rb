require 'rake'
require 'date'
require 'digest/md5'
require 'english'
require 'forwardable'
require 'time'
require 'yaml'
require 'concurrent'
require 'inifile'
require 'rbtree'
require 'sqlite3'
require 'sequel'

require 'abid/rake_extensions'
require 'abid/version'
require 'abid/waiter'
require 'abid/worker'
require 'abid/params_parser'
require 'abid/play'
require 'abid/state'
require 'abid/task'
require 'abid/task_manager'
require 'abid/dsl_definition'
require 'abid/application'

module Abid
  FIXNUM_MAX = (2**(0.size * 8 - 2) - 1) # :nodoc:
end