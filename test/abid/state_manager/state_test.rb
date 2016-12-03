require 'test_helper'

module Abid
  module StateManager
    class StateTest < AbidTest
      def test_state
        state = State.create(name: 'name', params: '', digest: '')

        refute state.running? || state.successed? || state.failed?

        state.update(state: State::RUNNING)
        assert state.running?

        state.update(state: State::SUCCESSED)
        assert state.successed?

        state.update(state: State::FAILED)
        assert state.failed?
      end

      def test_check_running
        state = State.create(name: 'name', params: '', digest: '')

        state.check_running!

        state.update(state: State::RUNNING)
        assert_raises AlreadyRunningError do
          state.check_running!
        end
      end

      def test_find_by_job
        job1 = Job.new('name', a: 1)
        state1 = State.create(name: job1.name, params: job1.params_str, digest: job1.digest)

        job2 = Job.new('name', a: 2)
        State.create(name: job2.name, params: job2.params_str, digest: job2.digest)

        found = State.find_by_job(job1)
        assert_equal state1.id, found.id
      end

      def test_start
        job = Job.new('name', b: 1, a: Date.new(2000, 1, 1))
        state = job.state

        # Non-existing job
        state.start
        assert_equal 'name', state.name
        assert_equal "---\n:a: 2000-01-01\n:b: 1\n", state.params
        assert_equal job.digest, state.digest
        assert state.running?

        # Failed job
        state.update(state: State::FAILED)
        state.start
        assert state.running?

        # Running job
        state.update(state: State::RUNNING)
        assert_raises AlreadyRunningError do
          state.start
        end
      end

      def test_finish
        job = Job.new('name', b: 1, a: Date.new(2000, 1, 1))
        state = job.state

        # Non-existing job
        state.finish
        assert state.new? # do nothing

        # Failed job
        state.assume
        state.update(state: State::FAILED)
        state.finish
        assert state.failed? # do nothing

        # Running job
        state.start
        state.finish
        assert state.successed?

        # With an error
        state.start
        state.finish(StandardError.new)
        assert state.failed?
      end

      def test_assume
        job = Job.new('name', b: 1, a: Date.new(2000, 1, 1))

        # Non-existing job
        state = Job.new('name', b: 1, a: Date.new(2000, 1, 1)).state
        state.assume
        assert_equal 'name', state.name
        assert_equal "---\n:a: 2000-01-01\n:b: 1\n", state.params
        assert_equal job.digest, state.digest
        assert state.successed?

        # Failed job
        state.update(state: State::FAILED)
        state2 = Job.new('name', b: 1, a: Date.new(2000, 1, 1)).state
        state2.assume
        assert_equal state.id, state2.id
        assert_equal "---\n:a: 2000-01-01\n:b: 1\n", state2.params
        assert_equal job.digest, state2.digest
        assert state2.successed?

        # Running job
        state.update(state: State::RUNNING)
        state3 = Job.new('name', b: 1, a: Date.new(2000, 1, 1)).state
        assert_raises AlreadyRunningError do
          state3.assume
        end
        state3.assume(force: true)
        assert_equal state.id, state3.id
        assert_equal "---\n:a: 2000-01-01\n:b: 1\n", state3.params
        assert_equal job.digest, state3.digest
        assert state3.successed?
      end

      def test_filter
        states = Array.new(10) do |i|
          s = Job.new("job#{i % 2}:foo#{i}", i: i).state
          s.assume
          s.update(
            start_time: Time.new(2000, 1, 1, i),
            end_time: Time.new(2000, 1, 1, i + 1)
          )
          s
        end

        found = State.filter_by_prefix('job0:')
                     .filter_by_start_time(
                       after: Time.new(2000, 1, 1, 3),
                       before: Time.new(2000, 1, 1, 8)
                     ).order(:id).to_a
        assert_equal 3, found.length
        assert_equal states[4].id, found[0].id
        assert_equal states[6].id, found[1].id
        assert_equal states[8].id, found[2].id
      end

      def test_revoke
        states = Array.new(10) do |i|
          Job.new('job', i: i).state.tap(&:assume)
        end

        states[0].revoke
        assert_nil State[states[0].id]

        states[1].update(state: State::RUNNING)
        assert_raises AlreadyRunningError do
          states[1].revoke
        end
        states[1].revoke(force: true)
        assert_nil State[states[1].id]

        assert_equal 8, State.count
      end
    end
  end
end
