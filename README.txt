Logging

* {Homepage}[http://logging.rubyforge.org/]
* {Rubyforge Project}[http://rubyforge.org/projects/logging]
* email tim dot pease at gmail dot com

== DESCRIPTION:

Logging is a flexible logging library for use in Ruby programs based on the
design of Java's log4j library. It features a hierarchical logging system,
custom level names, multiple output destinations per log event, custom
formatting, and more.

== FEATURES:

* obtaining a logger
* where to log
* log statements
* changing the log level
 
== INSTALL:

  sudo gem install logging

== EXAMPLE:

== NOTES:

Although Logging is intended to supersede Log4r, it is not a one-to-one
replacement for the Log4r library. Most notably is the difference in namespaces
-- Logging vs. Log4r. Other differences include renaming Log4r::Outputter to
Logging::Appender and renaming Log4r::Formatter to Logging::Layout. These
changes were meant to bring the Logging class names more in line with the Log4j
class names.

== REQUIREMENTS:

Logging does not depend on any other installed libraries or gems.

== LICENSE:

Ruby
