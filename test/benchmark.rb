
require 'rubygems'

libpath = File.expand_path('../../lib', __FILE__)
$:.unshift libpath
require 'logging'

begin
  gem 'log4r'
  require 'log4r'
  $log4r = true
rescue LoadError
  $log4r = false
end

require 'benchmark'
require 'logger'

module Logging
  class Benchmark

    def run
      this_many = 300_000

      Logging.appenders.string_io(
        'sio',
        :layout => Logging.layouts.pattern(
          :pattern => '%.1l, [%d] %5l -- %c: %m\n',
          :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"
        )
      )
      sio = Logging.appenders['sio'].sio

      logging = ::Logging.logger('benchmark')
      logging.level = :warn
      logging.appenders = 'sio'

      logger = ::Logger.new sio
      logger.level = ::Logger::WARN

      log4r = if $log4r
        x = ::Log4r::Logger.new('benchmark')
        x.level = ::Log4r::WARN
        x.add ::Log4r::IOOutputter.new(
          'benchmark', sio,
          :formatter => ::Log4r::PatternFormatter.new(
            :pattern => "%.1l, [%d #\#{Process.pid}] %5l : %M\n",
            :date_pattern => "%Y-%m-%dT%H:%M:%S.\#{Time.now.usec}"
          )
        )
        x
      end

      puts "== Debug (not logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        bm.report('Logging:') {this_many.times {logging.debug 'not logged'}}
        bm.report('Logger:') {this_many.times {logger.debug 'not logged'}}
        bm.report('Log4r:') {this_many.times {log4r.debug 'not logged'}} if log4r
      end

      puts "\n== Warn (logged) ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging.warn 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger.warn 'logged'}}
        sio.seek 0
        bm.report('Log4r:') {this_many.times {log4r.warn 'logged'}} if log4r
      end

      puts "\n== Concat ==\n"
      ::Benchmark.bm(10) do |bm|
        sio.seek 0
        bm.report('Logging:') {this_many.times {logging << 'logged'}}
        sio.seek 0
        bm.report('Logger:') {this_many.times {logger << 'logged'}}
        puts "Log4r:      not supported" if log4r
      end

      Logging.appenders.file(
        'benchmark',
        :layout => Logging.layouts.pattern(
          :pattern => '%.1l, [%d] %5l -- %c: %m\n',
          :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"
        ),
        :async => true,
        :auto_flushing => true
      )

      logging_async = ::Logging.logger('benchmark')
      logging_async.level = :warn
      logging_async.appenders = 'benchmark'

      Logging.appenders.file(
        'benchmark2',
        :layout => Logging.layouts.pattern(
          :pattern => '%.1l, [%d] %5l -- %c: %m\n',
          :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"
        ),
        :async => false,
        :auto_flushing => true
      )

      logging_sync = ::Logging.logger('benchmark')
      logging_sync.level = :warn
      logging_sync.appenders = 'benchmark2'

      puts "\n== File ==\n"
      ::Benchmark.bm(20) do |bm|
        bm.report('Logging (Async):') {this_many.times {logging_async << 'logged'}}
        File.delete('benchmark')

        bm.report('Logging (Sync):') {this_many.times {logging_sync << 'logged'}}
        File.delete('benchmark2')
      end
    end

  end  # class Benchmark
end  # module Logging


if __FILE__ == $0
  bm = ::Logging::Benchmark.new
  bm.run
end
