require 'yaml'

YAML::ENGINE.yamler = 'syck'

ActionController::Renderers.add :csv do |csv,options|
  csv = csv.respond_to?(:to_csv) ? csv.to_csv : csv
  self.content_type ||= Mime::CSV
  self.response_body = csv
end

class Array
  def to_csv(options = Hash.new)
    out = self.first.as_csv.keys.join("\t") + "\n"
    self.each do |el|
      out << el.as_csv.values.join("\t") + "\n"
    end
    return out
  end
end

class Hash
  def get_name
    return self[:name]
  end
  def get_path
    return self[:path]
  end
end