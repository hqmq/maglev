class Behavior

  primitive_nobridge 'include', 'includeRubyModule:'

  def protected(name)
  end
  
  def private(name)
  end

  def alias(name)
  end
  
  def inspect
    name
  end
  
  def to_s
    name
  end

  def const_get(name)
    name
  end

end
