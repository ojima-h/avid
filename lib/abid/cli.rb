require 'thor'

module Abid
  class CLI < Thor
    class_option :config_file, aliases: '-C', desc: 'config file path'

    def initialize(*args)
      super(*args)
      Abid.config.load(options[:config_file])
    end

    desc 'config', 'Show current config'
    def config
      puts Abid.config.to_yaml
    end

    desc 'migrate', 'Run database migration'
    def migrate
      require 'abid/cli/migrate'
      Migrate.new(options).run
    end

    desc 'assume TASK [TASKS..] [PARAMS]', 'Assume the job to be SUCCESSED'
    option :force, type: :boolean, aliases: '-f',
                   desc: 'set the state even if the job is running'
    def assume(task, *rest_args)
      require 'abid/cli/assume'
      Assume.new(options, [task, *rest_args]).run
    rescue AlreadyRunningError
      exit 1
    end

    desc 'list [PREFIX]', 'List jobs'
    option :after, type: :string, aliases: '-a', desc: 'start time fliter'
    option :before, type: :string, aliases: '-b', desc: 'start time filter'
    def list(prefix = nil)
      require 'abid/cli/list'
      List.new(options, prefix).run
    end
    map ls: :list

    desc 'revoke JOB_ID...', 'Revoke jobs history'
    option :force, type: :boolean, aliases: '-f',
                   desc: 'revoke the states even if the job is running'
    option :quiet, type: :boolean, aliases: '-q',
                   desc: 'no prompt before removal'
    def revoke(job_id, *rest_args)
      require 'abid/cli/revoke'
      Revoke.new(options, [job_id, *rest_args]).run
    end
    map rm: :revoke
  end
end
