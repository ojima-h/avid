namespace :state do
  task default: :list

  desc 'Show play histories'
  play :list, extends: Abid::Play do
    set :volatile, true

    param :started_after, type: :time, default: nil
    param :started_before, type: :time, default: nil

    def run
      states = Abid::State.list(
        started_after: started_after,
        started_before: started_before
      )

      table = states.map do |state|
        params = state[:params].map do |k, v|
          v.to_s =~ /\s/ ? "#{k}='#{v}'" : "#{k}=#{v}"
        end.join(' ')

        if state[:start_time] && state[:end_time]
          time_diff = (state[:end_time] - state[:start_time]).to_i
          if time_diff >= 60*60*24
            exec_time = time_diff.div(60*60*24).to_s + " days"
          else
            exec_time = Time.at(time_diff).utc.strftime('%H:%M:%S').to_s
          end
        else
          exec_time = ''
        end

        [
          state[:id].to_s,
          state[:state].to_s,
          state[:name],
          params,
          state[:start_time].to_s,
          state[:end_time].to_s,
          exec_time
        ]
      end

      header = %w(id state name params start_time end_time exec_time)

      tab_width = header.each_with_index.map do |c, i|
        [c.length, table.map { |row| row[i].length }.max || 0].max
      end

      header.each_with_index do |c, i|
        print c.ljust(tab_width[i] + 2)
      end
      puts

      header.each_with_index do |_, i|
        print '-' * (tab_width[i] + 2)
      end
      puts

      table.map do |row|
        row.each_with_index do |v, i|
          print v.ljust(tab_width[i] + 2)
        end
        puts
      end
    end
  end

  desc 'Delete play history'
  task :revoke do |_t, args|
    args.extras.each { |id| Abid::State.revoke(id) }
  end
end
