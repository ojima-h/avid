require 'test_helper'

module Abid
  class PlayTest < AbidTest
    class SamplePlay < Abid::Play
      worker :dummy_worker

      param :date, type: :date
      param :dummy, type: :string, significant: false

      def setup
        needs :parent, date: date + 1
      end

      def run
        [worker, date, dummy]
      end
    end

    def setup
      @task = Abid::Task.new('sample', app)
      SamplePlay.helpers do
        def sample_helper
          :sample
        end
      end
      SamplePlay.task = @task
    end

    def test_definition
      play = SamplePlay.new(date: '2000-01-01', dummy: 'foo')
      play.setup
      ret = play.run

      assert_empty Abid::Play.params_spec
      assert_equal :dummy_worker, ret[0]
      assert_equal Date.new(2000, 1, 1), ret[1]
      assert_equal 'foo', ret[2]

      parent_name, parent_params = play.prerequisites.first
      assert_equal :parent, parent_name
      assert_equal Date.new(2000, 1, 2), parent_params[:date]
    end

    def test_equality
      play1 = SamplePlay.new(date: '2000-01-01', dummy: 'foo')
      play2 = SamplePlay.new(date: '2000-01-02', dummy: 'foo')
      play3 = SamplePlay.new(date: '2000-01-01', dummy: 'bar')

      assert !play1.eql?(play2)
      assert play1.eql?(play3)
    end

    def test_helper
      play = SamplePlay.new(date: '2000-01-01', dummy: 'foo')
      assert_equal :sample, play.sample_helper
    end
  end
end