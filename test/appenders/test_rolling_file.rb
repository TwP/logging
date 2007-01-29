# $Id$

require 'test/setup.rb'
require 'fileutils'

module TestLogging
module TestAppenders

  class TestRollingFile < Test::Unit::TestCase
    include LoggingTestCase

    TMP = 'tmp'

    def setup
      super
      FileUtils.rm_rf TMP if File.exist?(TMP)
      FileUtils.mkdir(TMP)
      @fn = File.join(TMP, 'test.log')
      @fn_fmt = File.join(TMP, 'test.%d.log')
      @glob = File.join(TMP, '*.log')
    end

    def teardown
      FileUtils.rm_rf TMP
    end

    def test_initialize
      assert_equal [], Dir.glob(@glob)

      # create a new appender
      ap = ::Logging::Appenders::RollingFile.new('test', :filename => @fn)
      assert File.exist?(@fn)
      assert_equal 0, File.size(@fn)

      ap << "Just a line of text\n"   # 20 bytes
      ap.flush
      assert_equal 20, File.size(@fn)
      ap.close

      # make sure we append to the current file (not truncate)
      ap = ::Logging::Appenders::RollingFile.new('test', :filename => @fn)
      assert_equal [@fn], Dir.glob(@glob)
      assert_equal 20, File.size(@fn)

      ap << "Just another line of text\n"   # 26 bytes
      ap.flush
      assert_equal 46, File.size(@fn)
      ap.close

      # setting the truncate option to true should roll the current log file
      # and create a new one
      ap = ::Logging::Appenders::RollingFile.new('test',
               :filename => @fn, :truncate => true)

      log1 = sprintf(@fn_fmt, 1)
      assert_equal [log1, @fn], Dir.glob(@glob).sort
      assert_equal 0, File.size(@fn)
      assert_equal 46, File.size(log1)

      ap << "Some more text in the new file\n"   # 31 bytes
      ap.flush
      assert_equal 31, File.size(@fn)
      ap.close
    end

    def test_keep
      assert_equal [], Dir.glob(@glob)

      (1..12).each do |cnt|
        name = sprintf(@fn_fmt, cnt)
        File.open(name,'w') {|fd| fd.write 'X'*cnt}
      end
      FileUtils.touch(@fn)

      # keep only five files
      ap = ::Logging::Appenders::RollingFile.new('test',
               :filename => @fn, :keep => 5)

      # we still have 13 files because we did not truncate the log file,
      # and hence, we did not roll all the log files
      assert_equal 13, Dir.glob(@glob).length

      # force the appender to roll the files
      ap.send :roll
      assert_equal 6, Dir.glob(@glob).length

      (1..5).each do |cnt|
        name = sprintf(@fn_fmt, cnt)
        assert_equal cnt-1, File.size(name)
      end
      ap.close
    end

    def test_max_age
      assert_equal [], Dir.glob(@glob)

      ap = ::Logging::Appenders::RollingFile.new('test',
               :filename => @fn, :max_age => 1)

      ap << "random message\n"
      assert_equal 1, Dir.glob(@glob).length

      sleep 1
      ap << "another random message\n"
      assert_equal 2, Dir.glob(@glob).length

      ap.close
    end

    def test_max_size
      assert_equal [], Dir.glob(@glob)

      ap = ::Logging::Appenders::RollingFile.new('test',
               :filename => @fn, :max_size => 100)

      ap << 'X' * 100; ap.flush
      assert_equal 1, Dir.glob(@glob).length
      assert_equal 100, File.size(@fn)

      # this character is appended to the log file (bringing its size to 101)
      # and THEN the file is rolled resulting in a new, empty log file
      ap << 'X'
      assert_equal 2, Dir.glob(@glob).length
      assert_equal 0, File.size(@fn)

      ap << 'X' * 100; ap.flush
      assert_equal 2, Dir.glob(@glob).length
      assert_equal 100, File.size(@fn)

      ap << 'X'
      assert_equal 3, Dir.glob(@glob).length
      assert_equal 0, File.size(@fn)

      ap.close
    end

  end  # class TestRollingFile
end  # module TestAppenders
end  # module TestLogging

# EOF
