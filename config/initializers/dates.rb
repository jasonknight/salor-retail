# Because Ruby and Rails are both gay when it comes
# to date parsing.

class << Date
  alias _parse_without_eu_format _parse
  def _parse(str, comp = false)
    str = str.to_s
    if /(\d{2})\.(\d{2})\.(\d{4})/ =~ str
      str = "#{$3}-#{$2}-#{$1}" 
    end
    ret = {}
    str.scan(/(\d{4})-(\d{2})-(\d{2})/) do |m|
      ret = {:year => m[0].to_i,:mon => m[1].to_i, :mday => m[2].to_i}
    end
    return ret
  end
end

class << Date
  def try_parse(string, default = nil)
    components = ParseDate.parsedate(string)
    components.first ? new(*components[0..2]) : default
  end
end
