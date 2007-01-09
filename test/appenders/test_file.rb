# $Id$

require 'test/setup.rb'
require 'fileutils'

module TestLogging
module TestAppenders

  class TestFile < Test::Unit::TestCase
    include LoggingTestCase

    TMP = 'tmp'

    def setup
      super
      FileUtils.rm_rf TMP if File.exist?(TMP)
      FileUtils.mkdir(TMP)
      FileUtils.mkdir [File.join(TMP, 'dir'), File.join(TMP, 'uw_dir')]
      FileUtils.chmod 0555, File.join(TMP, 'uw_dir')
      FileUtils.touch File.join(TMP, 'uw_file')
      FileUtils.chmod 0444, File.join(TMP, 'uw_file')
    end

    def teardown
      FileUtils.rm_rf TMP
    end

    def test_initialize
      log = File.join(TMP, 'uw_dir', 'file.log')
      assert_raise(StandardError) {::Logging::Appenders::File.new log}

      log = File.join(TMP, 'dir')
      assert_raise(StandardError) {::Logging::Appenders::File.new log}

      log = File.join(TMP, 'uw_file')
      assert_raise(StandardError) {::Logging::Appenders::File.new log}

      log = File.join(TMP, 'file.log')
      appender = ::Logging::Appenders::File.new log
      assert_equal log, appender.name
      appender << "This will be the first line\n"
      appender << "This will be the second line\n"
      File.open(log, 'r') do |file|
        assert_equal "This will be the first line\n", file.readline
        assert_equal "This will be the second line\n", file.readline
        assert_raise(EOFError) {file.readline}
      end
      appender.close

      appender = ::Logging::Appenders::File.new log
      assert_equal log, appender.name
      appender << "This will be the third line\n"
      File.open(log, 'r') do |file|
        assert_equal "This will be the first line\n", file.readline
        assert_equal "This will be the second line\n", file.readline
        assert_equal "This will be the third line\n", file.readline
        assert_raise(EOFError) {file.readline}
      end
      appender.close

      appender = ::Logging::Appenders::File.new log, :truncate => true
      assert_equal log, appender.name
      appender << "The file was truncated\n"
      File.open(log, 'r') do |file|
        assert_equal "The file was truncated\n", file.readline
        assert_raise(EOFError) {file.readline}
      end
      appender.close
    end

  end  # class TestFile

end  # module TestAppenders
end  # module TestLogging

# EOF
