# $Id$

require 'stringio'
require 'yaml'
require 'test/setup.rb'

module TestLogging
module TestConfig

  class TestYamlConfigurator < Test::Unit::TestCase
    include LoggingTestCase

    TMP = 'tmp'

    def setup
      super
      FileUtils.rm_rf TMP
      FileUtils.mkdir TMP
    end

    def teardown
      super
      FileUtils.rm_rf TMP
    end

    def test_class_load
      assert_raise(::Logging::Config::YamlConfigurator::Error) {
        ::Logging::Config::YamlConfigurator.load(Object.new)
      }

      begin
        fd = File.open('data/logging.yaml','r')
        assert_nothing_raised {
          ::Logging::Config::YamlConfigurator.load(fd)
        }
      ensure
        fd.close
      end
    end

    def test_initialize
      io = StringIO.new
      io << YAML.dump({:one => 1, :two => 2, :three => 3})
      io.seek 0

      assert_raise(::Logging::Config::YamlConfigurator::Error) {
        ::Logging::Config::YamlConfigurator.new(io)
      }
    end

  end  # class TestYamlConfigurator

end  # module TestConfig
end  # module TestLogging

# EOF
