module Abid
  class Engine
    # @!visibility private

    # Executor operates each task execution.
    class Executor
      def initialize(job, args)
        @job = job
        @args = args

        @process = job.process
        @state = @process.state_service.find
        @prerequisites = job.prerequisites.map(&:process)
      end

      # Check if the task should be executed.
      #
      # @return [Boolean] false if the task should not be executed.
      def prepare
        return unless @process.prepare
        return false if precheck_to_cancel
        return false if precheck_to_skip
        true
      end

      # Start processing the task.
      #
      # The task is executed asynchronously.
      #
      # @return [Boolean] false if the task is not executed
      def start
        return false unless @prerequisites.all?(&:complete?)

        return false if check_to_cancel
        return false if check_to_skip

        return false unless @process.start
        execute_or_wait
        true
      end

      private

      # Cancel the task if it should be.
      # @return [Boolean] true if cancelled
      def precheck_to_cancel
        return false if @job.repair?
        return false unless @state.failed?
        return false if @job.root?
        @process.cancel(Error.new('task has been failed'))
      end

      # Skip the task if it should be.
      # @return [Boolean] true if skipped
      def precheck_to_skip
        return @process.skip unless @job.task.concerned?

        return false if @job.repair? && !@prerequisites.empty?
        return false unless @state.successed?
        @process.skip
      end

      # Cancel the task if it should be.
      # @return [Boolean] true if cancelled
      def check_to_cancel
        return false if @prerequisites.empty?
        return false if @prerequisites.all? { |p| !p.failed? && !p.cancelled? }
        @process.cancel
      end

      # Skip the task if it should be.
      # @return [Boolean] true if skipped
      def check_to_skip
        return @process.skip unless @job.task.needed?

        return false if @prerequisites.empty?
        return false unless @job.repair?
        return false if @prerequisites.any?(&:successed?)
        @process.skip
      end

      # Post the task if no external process executing the same task, wait the
      # task finished otherwise.
      def execute_or_wait
        if @process.state_service.try_start
          @job.worker.post { @process.capture_exception { execute } }
        else
          Waiter.new(@job).wait
        end
      end

      def execute
        _, error = safe_execute

        @process.state_service.finish(error)
        @process.finish(error)
      end

      def safe_execute
        @job.task.execute(@args)
        true
      rescue => error
        [false, error]
      end
    end
  end
end
