# $Id$

class Hash

  # call-seq:
  #    getopt( key, default = nil, :as => class )
  #
  # Returns the value associated with the _key_. If the has does not contain
  # the _key_, then the _default_ value is returned.
  #
  # Optionally, the value can be converted into to an instance of the given
  # _class_. The supported classes are:
  #
  #     Integer
  #     Float
  #     Array
  #     String
  #     Symbol
  #
  # If the value is +nil+, then no converstion will be performed.
  #
  def getopt( *args )
    opts = Hash === args.last ? args.pop : {}
    key, default = args

    val = if has_key?(key);                self[key]
          elsif has_key?(key.to_s);        self[key.to_s]
          elsif has_key?(key.to_s.intern); self[key.to_s.intern]
          else default end

    return if val.nil?
    return val unless opts.has_key?(:as)

    case opts[:as].name.intern
    when :Integer; Integer(val)
    when :Float;   Float(val)
    when :Array;   Array(val)
    when :String;  String(val)
    when :Symbol;  String(val).intern
    else val end
  end
end

# EOF
