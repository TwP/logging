# Equivalent to a header guard in C/C++
# Used to prevent the class/module from being loaded more than once
unless defined? LOGGING_TEST_SETUP
LOGGING_TEST_SETUP = true

require "rubygems"
require "test/unit"
require "tmpdir"

LOGGING_TEST_TMPDIR = Dir.mktmpdir("logging")
Test::Unit.at_exit do
  FileUtils.remove_entry(LOGGING_TEST_TMPDIR)
end

if Test::Unit::TestCase.respond_to? :test_order=
  Test::Unit::TestCase.test_order = :random
end

require File.expand_path("../../lib/logging", __FILE__)

module TestLogging
  module LoggingTestCase

    def setup
      super
      Logging.reset
      @tmpdir = LOGGING_TEST_TMPDIR
      FileUtils.rm_rf(Dir.glob(File.join(@tmpdir, "*")))
    end

    def teardown
      super
      FileUtils.rm_rf(Dir.glob(File.join(@tmpdir, "*")))
    end
  end
end

end
