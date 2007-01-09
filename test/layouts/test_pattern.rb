# $Id$

require 'test/setup.rb'

module TestLogging
module TestLayouts

  class TestPattern < Test::Unit::TestCase
    include LoggingTestCase

    def setup
      super
      ::Logging.define_levels %w(debug info warn error fatal)
      @layout = ::Logging::Layouts::Pattern.new
      @date_fmt = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
    end

    def test_format
      fmt = '\[' + @date_fmt + '\] %s -- %s : %s\n'

      event = ::Logging::LogEvent.new('ArrayLogger', 'INFO',
                                      ['log message'], false)
      rgxp  = Regexp.new(sprintf(fmt, 'INFO ', 'ArrayLogger', 'log message'))
      assert_match rgxp, @layout.format(event)

      event.data = [[1, 2, 3, 4]]
      rgxp  = Regexp.new(sprintf(fmt, 'INFO ', 'ArrayLogger', '<Array> 1234'))
      assert_match rgxp, @layout.format(event)

      event.level = 'DEBUG'
      event.data = [[1, 2, 3, 4], 'and some message']
      rgxp  = Regexp.new(
                  sprintf(fmt, 'DEBUG', 'ArrayLogger', '<Array> 1234') +
                  sprintf(fmt, 'DEBUG', 'ArrayLogger', 'and some message'))
      assert_match rgxp, @layout.format(event)

      event.logger = 'Test'
      event.level = 'FATAL'
      event.data = [[1, 2, 3, 4], 'and some message', Exception.new]
      rgxp  = Regexp.new(
                  sprintf(fmt, 'FATAL', 'Test', '<Array> 1234') +
                  sprintf(fmt, 'FATAL', 'Test', 'and some message') +
                  sprintf(fmt, 'FATAL', 'Test', '<Exception> Exception'))
      assert_match rgxp, @layout.format(event)
    end

    def test_format_date
      rgxp = Regexp.new @date_fmt
      assert_match rgxp, @layout.format_date
    end

  end  # class TestBasic
end  # module TestLayouts
end  # module TestLogging

# EOF
