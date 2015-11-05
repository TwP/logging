# -*- encoding: utf-8 -*-
# stub: logging 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "logging"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Tim Pease"]
  s.date = "2015-03-29"
  s.license = "MIT"
  s.description = "Logging is a flexible logging library for use in Ruby programs based on the\ndesign of Java's log4j library. It features a hierarchical logging system,\ncustom level names, multiple output destinations per log event, custom\nformatting, and more."
  s.email = "tim.pease@gmail.com"
  s.extra_rdoc_files = ["History.txt"]
  s.files = [".gitignore", ".travis.yml", "History.txt", "README.md", "Rakefile", "examples/appenders.rb", "examples/classes.rb", "examples/colorization.rb", "examples/custom_log_levels.rb", "examples/fork.rb", "examples/formatting.rb", "examples/hierarchies.rb", "examples/layouts.rb", "examples/lazy.rb", "examples/loggers.rb", "examples/mdc.rb", "examples/names.rb", "examples/rspec_integration.rb", "examples/simple.rb", "lib/logging.rb", "lib/logging/appender.rb", "lib/logging/appenders.rb", "lib/logging/appenders/buffering.rb", "lib/logging/appenders/console.rb", "lib/logging/appenders/file.rb", "lib/logging/appenders/io.rb", "lib/logging/appenders/rolling_file.rb", "lib/logging/appenders/string_io.rb", "lib/logging/appenders/syslog.rb", "lib/logging/color_scheme.rb", "lib/logging/diagnostic_context.rb", "lib/logging/filter.rb", "lib/logging/filters.rb", "lib/logging/filters/level.rb", "lib/logging/layout.rb", "lib/logging/layouts.rb", "lib/logging/layouts/basic.rb", "lib/logging/layouts/parseable.rb", "lib/logging/layouts/pattern.rb", "lib/logging/log_event.rb", "lib/logging/logger.rb", "lib/logging/proxy.rb", "lib/logging/rails_compat.rb", "lib/logging/repository.rb", "lib/logging/root_logger.rb", "lib/logging/utils.rb", "lib/logging/version.rb", "lib/rspec/logging_helper.rb", "lib/spec/logging_helper.rb", "logging.gemspec", "script/bootstrap", "test/appenders/test_buffered_io.rb", "test/appenders/test_console.rb", "test/appenders/test_file.rb", "test/appenders/test_io.rb", "test/appenders/test_periodic_flushing.rb", "test/appenders/test_rolling_file.rb", "test/appenders/test_string_io.rb", "test/appenders/test_syslog.rb", "test/benchmark.rb", "test/layouts/test_basic.rb", "test/layouts/test_color_pattern.rb", "test/layouts/test_json.rb", "test/layouts/test_pattern.rb", "test/layouts/test_yaml.rb", "test/setup.rb", "test/test_appender.rb", "test/test_color_scheme.rb", "test/test_filter.rb", "test/test_layout.rb", "test/test_log_event.rb", "test/test_logger.rb", "test/test_logging.rb", "test/test_mapped_diagnostic_context.rb", "test/test_nested_diagnostic_context.rb", "test/test_proxy.rb", "test/test_repository.rb", "test/test_root_logger.rb", "test/test_utils.rb"]
  s.homepage = "http://rubygems.org/gems/logging"
  s.rdoc_options = ["--main", "README.md"]
  s.rubyforge_project = "logging"
  s.rubygems_version = "2.2.2"
  s.summary = "A flexible and extendable logging library for Ruby"
  s.test_files = ["test/appenders/test_buffered_io.rb", "test/appenders/test_console.rb", "test/appenders/test_file.rb", "test/appenders/test_io.rb", "test/appenders/test_periodic_flushing.rb", "test/appenders/test_rolling_file.rb", "test/appenders/test_string_io.rb", "test/appenders/test_syslog.rb", "test/layouts/test_basic.rb", "test/layouts/test_color_pattern.rb", "test/layouts/test_json.rb", "test/layouts/test_pattern.rb", "test/layouts/test_yaml.rb", "test/test_appender.rb", "test/test_color_scheme.rb", "test/test_filter.rb", "test/test_layout.rb", "test/test_log_event.rb", "test/test_logger.rb", "test/test_logging.rb", "test/test_mapped_diagnostic_context.rb", "test/test_nested_diagnostic_context.rb", "test/test_proxy.rb", "test/test_repository.rb", "test/test_root_logger.rb", "test/test_utils.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<little-plugger>, ["~> 1.1"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.10"])
      s.add_development_dependency(%q<flexmock>, ["~> 1.0"])
      s.add_development_dependency(%q<bones-git>, ["~> 1.3"])
      s.add_development_dependency(%q<bones>, [">= 3.8.3"])
    else
      s.add_dependency(%q<little-plugger>, ["~> 1.1"])
      s.add_dependency(%q<multi_json>, ["~> 1.10"])
      s.add_dependency(%q<flexmock>, ["~> 1.0"])
      s.add_dependency(%q<bones-git>, ["~> 1.3"])
      s.add_dependency(%q<bones>, [">= 3.8.3"])
    end
  else
    s.add_dependency(%q<little-plugger>, ["~> 1.1"])
    s.add_dependency(%q<multi_json>, ["~> 1.10"])
    s.add_dependency(%q<flexmock>, ["~> 1.0"])
    s.add_dependency(%q<bones-git>, ["~> 1.3"])
    s.add_dependency(%q<bones>, [">= 3.8.3"])
  end
end
