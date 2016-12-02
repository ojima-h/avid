require 'rake'
require 'date'
require 'digest/md5'
require 'English'
require 'forwardable'
require 'monitor'
require 'time'
require 'yaml'
require 'concurrent'
require 'rbtree'
require 'sqlite3'
require 'sequel'

require 'abid/config'
require 'abid/error'
require 'abid/params_format'
require 'abid/state_manager'
require 'abid/job'

require 'abid/rake_extensions'
require 'abid/version'
require 'abid/abid_module'
require 'abid/waiter'
require 'abid/worker'
require 'abid/params_parser'
require 'abid/play_core'
require 'abid/play'
require 'abid/session'
require 'abid/state'
require 'abid/task'
require 'abid/mixin_task'
require 'abid/task_manager'
require 'abid/dsl_definition'
require 'abid/application'

module Abid
  FIXNUM_MAX = (2**(0.size * 8 - 2) - 1) # :nodoc:
end
