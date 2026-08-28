require File.expand_path('setup', File.dirname(__FILE__))

module TestLogging

  # Guards the deferred `require 'yaml'` calls in Layout#try_yaml and
  # Parseable.create_yaml_format_method. These run in a subprocess because
  # this one has already loaded yaml by way of the layout tests.
  class TestRequire < Test::Unit::TestCase

    YAML_LOADED = '$LOADED_FEATURES.any? { |f| File.basename(f) == "yaml.rb" }'

    def subprocess( script )
      lib = File.expand_path('../lib', File.dirname(__FILE__))
      IO.popen([RbConfig.ruby, '-I', lib, '-e', script], &:read)
    end

    def test_requiring_logging_does_not_load_yaml
      assert_equal 'false', subprocess("require 'logging'; print #{YAML_LOADED}")
    end

    def test_yaml_layout_loads_yaml
      script = "require 'logging'; " \
               "Logging::Layouts::Parseable.yaml; " \
               "print #{YAML_LOADED}"
      assert_equal 'true', subprocess(script)
    end

    def test_yaml_object_format_still_works
      script = "require 'logging'; " \
               "l = Logging::Layouts::Basic.new(:obj_format => :yaml); " \
               "print l.send(:format_obj, {'a' => 1}).include?('a')"
      assert_equal 'true', subprocess(script)
    end

    def test_yaml_layout_still_formats_events
      script = "require 'logging'; " \
               "lay = Logging::Layouts::Parseable.yaml; " \
               "ev = Logging::LogEvent.new('L', 1, ['hi'], false); " \
               "print lay.format(ev).include?('hi')"
      assert_equal 'true', subprocess(script)
    end
  end
end
