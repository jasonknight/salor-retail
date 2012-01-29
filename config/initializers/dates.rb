# Because Ruby and Rails are both gay when it comes
# to date parsing.

class << Date
  alias _parse_without_eu_format _parse
  def _parse(str, comp = false)
    str = str.to_s
    str = "#{$3}-#{$2}-#{$1}" if /(\d{2})\.(\d{2})\.(\d{4})/ =~ str
    _parse_without_eu_format(str, comp)
  end
end

class << Date
  def try_parse(string, default = nil)
    components = ParseDate.parsedate(string)
    components.first ? new(*components[0..2]) : default
  end
end
