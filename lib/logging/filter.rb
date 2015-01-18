module Logging

  # The +Filter+ class allows for filtering messages based on event
  # properties independently of the standard minimum-level restriction.
  #
  # All other Filters inherit from this class, and must override the
  # +allow+ method to return true if the event should be allowed into
  # the log, and false otherwise.
  #
  class Filter

    # call-seq:
    #    allow( event )
    #
    # Returns true if the given _event_ should be allowed to proceed
    # to the log, and false if it should be prevented.
    def allow( event )
      true
    end
  end
end