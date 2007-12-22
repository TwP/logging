# $Id$

class Hash
  def getopt( key, default = nil )
    return self[key] if has_key?(key)
    key = key.to_s; return self[key] if has_key?(key)
    key = key.intern; return self[key] if has_key?(key)
    default
  end

  def delopt( key, default = nil )
    return delete(key) if has_key?(key)
    key = key.to_s; return delete(key) if has_key?(key)
    key = key.intern; return delete(key) if has_key?(key)
    default
  end
end

# EOF
