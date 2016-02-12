namespace :core do
  desc 'Base play that sleep until given condition satisfied'
  play :waiter do
    volatile

    define_attribute(:interval) { 30 }
    define_attribute(:timeout) { 3600 }

    worker :waiter

    def wait_until(elapsed)
      true
    end

    def run
      start_time = Time.now.to_f
      elapsed = 0
      until wait_until(elapsed)
        elapsed = Time.now.to_f - start_time

        fail 'timeout exceeded' if elapsed >= timeout

        sleep interval
      end
    end
  end
end
