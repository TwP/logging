require 'set'

module Logging
  module Filters

    # The +Level+ filter class provides a simple level-based filtering mechanism
    # that filters messages to only include those from an enumerated list of
    # levels to log.
    class Level < ::Logging::Filter

      # call-seq:
      #    Level.new ( *levels )
      #
      # Creates a new level filter that will only allow the given _levels_ to
      # propagate through to the logger.  The _levels_ should be given in symbolic
      # form.
      def initialize(*levels)
        super()
        @levels = Set.new(levels.map { |level| ::Logging::level_num(level) })
      end

      def allow(event)
        @levels.include?(event.level)
      end

    end
  end
end
