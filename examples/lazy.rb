# :stopdoc:
#
# It happens sometimes that it is very expensive to construct a logging
# message, e.g. if a big object structure has to be traversed in an
# object.to_s method. But if the message is logged with a level that
# doesn't actually get displayed, it would be a waste of time to
# construct it. The logging framework provides a way to
# address this in an elegant way using lazy evaluation.
#

  require 'logging'

  Logging.logger.root.appenders = Logging.appenders.stdout
  Logging.logger.root.level = :info

  # We use this dummy method in order to see if the method gets called, but in practice,
  # this method might do complicated string operations to construct a log message.
  def expensive_method
    puts "Called!"
    "Expensive message"
  end

  log = Logging.logger['Lazy']

  # If you log this message the usual way, expensive_method gets called before
  # debug, hence the Logging framework has no chance to stop it from being executed
  # immediately.
  log.info("Normal")
  log.debug(expensive_method)

  # If we put the message into a block, then the block is only executed
  # if the message is actually logged.
  log.info("Block unused")
  log.debug { expensive_method }

  # If the log message is actually logged, then the block is of course
  # executed and the log message appears as expected.
  log.info("Block used")
  log.warn { expensive_method }

# :startdoc:
