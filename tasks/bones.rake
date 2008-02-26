# $Id$

require 'pp'
require 'stringio'

namespace :bones do

  desc 'Show the PROJ open struct'
  task :debug do |t|
    atr = if ARGV.length == 2
      t.application.top_level_tasks.pop
    end
    sio = StringIO.new
    sep = "\n" + ' '*27
    fmt = "%23s => %s"

    if atr
      PP.pp(PROJ.send(atr.to_sym), sio, 49)
      sio.seek 0
      val = sio.read
      val = val.split("\n").join(sep)

      puts fmt % [atr, val]
    else
      h = PROJ.instance_variable_get(:@table)
      h.keys.map {|k| k.to_s}.sort.each do |k|
        sio.truncate 0
        PP.pp(h[k.to_sym], sio, 49)
        sio.seek 0
        val = sio.read
        val = val.split("\n").join(sep)

        puts fmt % [k, val]
      end
    end
  end

end  # namespace :bones

# EOF
