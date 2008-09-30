Logging
    by Tim Pease

* {Homepage}[http://logging.rubyforge.org/]
* {Rubyforge Project}[http://rubyforge.org/projects/logging]
* email tim dot pease at gmail dot com

== DESCRIPTION

Logging is a flexible logging library for use in Ruby programs based on the
design of Java's log4j library. It features a hierarchical logging system,
custom level names, multiple output destinations per log event, custom
formatting, and more.

== INSTALL

   sudo gem install logging

== EXAMPLE

This example configures a logger to output messages in a format similar to the
core ruby Logger class. Only log messages that are warnings or higher will be
logged.

   require 'logging'

   logger = Logging.logger(STDOUT)
   logger.level = :warn

   logger.debug "this debug message will not be output by the logger"
   logger.warn "this is your last warning"

In this example, a single logger is crated that will append to STDOUT and to a
file. Only log messages that are informational or higher will be logged.

   require 'logging'

   logger = Logging::Logger['example_logger']
   logger.add_appenders(
       Logging::Appender.stdout,
       Logging::Appenders::File.new('example.log')
   )
   logger.level = :info

   logger.debug "this debug message will not be output by the logger"
   logger.info "just some friendly advice"

The Logging library was created to allow each class in a program to have its
own configurable logger. The logging level for a particular class can be
changed independently of all other loggers in the system. This example shows
the recommended way of accomplishing this.

   require 'logging'

   Logging::Logger['FirstClass'].level = :warn
   Logging::Logger['SecondClass'].level = :debug

   class FirstClass
     def initialize
       @log = Logging::Logger[self]
     end

     def some_method
       @log.debug "some method was called on #{self.inspect}"
     end
   end

   class SecondClass
     def initialize
       @log = Logging::Logger[self]
     end

     def another_method
       @log.debug "another method was called on #{self.inspect}"
     end
   end

== NOTES

Although Logging is intended to supersede Log4r, it is not a one-to-one
replacement for the Log4r library. Most notably is the difference in namespaces
-- Logging vs. Log4r. Other differences include renaming Log4r::Outputter to
Logging::Appender and renaming Log4r::Formatter to Logging::Layout. These
changes were meant to bring the Logging class names more in line with the Log4j
class names.

== REQUIREMENTS

Logging requires the "lockfile" gem to run and the "flexmock" gem to run the
tests"

== LICENSE

Ruby
