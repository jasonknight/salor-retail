class Hash
  def replace_nested_value_by(keys, value)
    if keys.size > 1
      #puts "recursion"
      self[keys.first].replace_nested_value_by(keys[1..-1], value)
    elsif keys.size == 1
      #puts "setting #{ keys.inspect} to #{ value.inspect}"
      self[keys.first] = value
    end
  end
end