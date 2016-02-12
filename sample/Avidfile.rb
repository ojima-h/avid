task default: :sample

desc 'sample task'
play :sample do
  param :date, type: :date

  def setup
    needs 'parents:sample', date: date - 1
  end

  def run
    puts "sample called with date=#{date}"
  end
end

namespace :parents do
  desc 'sample parent task'
  play :sample do
    param :date, type: :date

    def run
      puts "parents:sample called with date=#{date}"
    end
  end
end

desc 'broken task'
play :failure do
  def run
    fail
  end
end

desc 'waiter smaple'
play :waiter_sample, extends: 'core:waiter' do
  interval 1

  def wait_until(elapsed)
    p elapsed
    elapsed > 5
  end
end
