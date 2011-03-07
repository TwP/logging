
# color_scheme.rb
#
# Created by Jeremy Hinegardner on 2007-01-24
# Copyright 2007.  All rights reserved
#
# This is Free Software.  See LICENSE and COPYING for details

module Logging

  # ColorScheme objects encapsulate a named set of colors to be used in the
  # colors() method call. For example, by applying a ColorScheme that
  # has a <tt>:warning</tt> color then the following could be used:
  #
  #   scheme.color("This is a warning", :warning)
  #
  # A ColorScheme contains named sets of color constants.
  #
  class ColorScheme

    # Create an instance of Logging::ColorScheme. The customization can
    # happen as a passed in Hash or via the yielded block.  Key's are
    # converted to <tt>strings</tt> and values are converted to color
    # constants.
    #
    def initialize( h = nil )
      @scheme = Hash.new
      load_from_hash(h) unless h.nil?
      yield self if block_given?
    end

    # Load multiple colors from key/value pairs.
    #
    def load_from_hash( h )
      h.each_pair do |color_tag, constants|
        self[color_tag] = constants
      end
    end

    # Does this color scheme include the given tag name?
    #
    def include?( color_tag )
      @scheme.key?(to_symbol(color_tag))
    end

    # Allow the scheme to be accessed like a Hash.
    #
    def []( color_tag )
      @scheme[to_symbol(color_tag)]
    end

    # Allow the scheme to be set like a Hash.
    #
    def []=( color_tag, constants )
      @scheme[to_symbol(color_tag)] = constants.map { |c| to_constant(c) }
    end

    # This method provides easy access to ANSI color sequences, without the user
    # needing to remember to CLEAR at the end of each sequence.  Just pass the
    # _string_ to color, followed by a list of _colors_ you would like it to be
    # affected by.  The _colors_ can be ColorScheme class constants, or symbols
    # (:blue for BLUE, for example).  A CLEAR will automatically be embedded to
    # the end of the returned String.
    #
    def color( string, *colors )
      colors.map! { |color|
        color_tag = to_symbol(color)
        @scheme.key?(color_tag) ? @scheme[color_tag] : to_constant(color)
      }
      "#{colors.flatten.join}#{string}#{CLEAR}"
    end

  private

    # Return a normalized representation of a color name.
    #
    def to_symbol( t )
      t.to_s.downcase
    end

    # Return a normalized representation of a color setting.
    #
    def to_constant( v )
      ColorScheme.const_get(v.to_s.upcase)
    rescue NameError
      return  v
    end

    # Embed in a String to clear all previous ANSI sequences.  This *MUST* be
    # done before the program exits!
    CLEAR      = "\e[0m".freeze
    RESET      = CLEAR              # An alias for CLEAR.
    ERASE_LINE = "\e[K".freeze      # Erase the current line of terminal output.
    ERASE_CHAR = "\e[P".freeze      # Erase the character under the cursor.
    BOLD       = "\e[1m".freeze     # The start of an ANSI bold sequence.
    DARK       = "\e[2m".freeze     # The start of an ANSI dark sequence.  (Terminal support uncommon.)
    UNDERLINE  = "\e[4m".freeze     # The start of an ANSI underline sequence.
    UNDERSCORE = UNDERLINE          # An alias for UNDERLINE.
    BLINK      = "\e[5m".freeze     # The start of an ANSI blink sequence.  (Terminal support uncommon.)
    REVERSE    = "\e[7m".freeze     # The start of an ANSI reverse sequence.
    CONCEALED  = "\e[8m".freeze     # The start of an ANSI concealed sequence.  (Terminal support uncommon.)

    BLACK      = "\e[30m".freeze    # Set the terminal's foreground ANSI color to black.
    RED        = "\e[31m".freeze    # Set the terminal's foreground ANSI color to red.
    GREEN      = "\e[32m".freeze    # Set the terminal's foreground ANSI color to green.
    YELLOW     = "\e[33m".freeze    # Set the terminal's foreground ANSI color to yellow.
    BLUE       = "\e[34m".freeze    # Set the terminal's foreground ANSI color to blue.
    MAGENTA    = "\e[35m".freeze    # Set the terminal's foreground ANSI color to magenta.
    CYAN       = "\e[36m".freeze    # Set the terminal's foreground ANSI color to cyan.
    WHITE      = "\e[37m".freeze    # Set the terminal's foreground ANSI color to white.

    ON_BLACK   = "\e[40m".freeze    # Set the terminal's background ANSI color to black.
    ON_RED     = "\e[41m".freeze    # Set the terminal's background ANSI color to red.
    ON_GREEN   = "\e[42m".freeze    # Set the terminal's background ANSI color to green.
    ON_YELLOW  = "\e[43m".freeze    # Set the terminal's background ANSI color to yellow.
    ON_BLUE    = "\e[44m".freeze    # Set the terminal's background ANSI color to blue.
    ON_MAGENTA = "\e[45m".freeze    # Set the terminal's background ANSI color to magenta.
    ON_CYAN    = "\e[46m".freeze    # Set the terminal's background ANSI color to cyan.
    ON_WHITE   = "\e[47m".freeze    # Set the terminal's background ANSI color to white.

  end  # ColorScheme
end  # Logging

