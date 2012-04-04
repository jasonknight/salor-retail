String.class_eval do
  def split_at_first_available(char,index=0)
    if self.length < index then
      return [self]
    end
    # Otherwise, we need to see what is at that location
    start = index
    while start >= 0 
      if self[start] == char then
        part = self.slice(0,start).strip
        part2 = self.slice(start,self.length).strip
        ar = [part]
        if part2.length > index then
          ar += part2.split_at_first_available(char,index)
        else
          ar << part2
        end
        return ar
      end
      start -= 1
      if start < 0 then
        return [self]
        raise "Could not find #{char} in string."
      end
    end
  end
end
