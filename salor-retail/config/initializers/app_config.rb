require 'yaml'
YAML::ENGINE.yamler = 'syck'
NilClass.class_eval do
  METHOD_CLASS_MAP = Hash.new

  def self.add_whiner(klass)
    methods = klass.public_instance_methods - public_instance_methods
    class_name = klass.name
    methods.each { |method| METHOD_CLASS_MAP[method.to_sym] = class_name }
  end

  add_whiner ::Array

  # Raises a RuntimeError when you attempt to call +id+ on +nil+.
  
  def id
    return 0 #if RAILS_ENV == 'production'
    raise RuntimeError, "Called id for nil, which would mistakenly be #{object_id} -- if you really wanted the id of nil, use object_id", caller
  end

  private
    def method_missing(method, *args)
      if method.to_s == 'zero?' then
        return true
      end
      if method.to_s == 'merge' then
        return {}
      end
      if 1.respond_to? method or args.first.class == Fixnum then
        return 0 #if RAILS_ENV == 'production'
      end
      if ''.respond_to? method or args.first.class == String then
        return '' #if RAILS_ENV == 'production'
      end
      if AppConfig.standalone == true and method == :get_owner then
        return User.first
      end
      if klass = METHOD_CLASS_MAP[method]
        raise_nil_warning_for klass, method, caller
      else
        puts "### Raising errors because of" + method.to_s
        Kernel.caller(0).each do |caller|
          puts caller
        end
        super
      end
    end

    # Raises a NoMethodError when you attempt to call a method on +nil+.
    def raise_nil_warning_for(class_name = nil, selector = nil, with_caller = nil)
      message = "You have a nil object when you didn't expect it!"
      message << "\nYou might have expected an instance of #{class_name}." if class_name
      message << "\nThe error occurred while evaluating nil.#{selector}" if selector

      raise NoMethodError, message, with_caller || caller
    end
end
class String
  def valid_utf8?
    unpack("U") rescue nil
  end

  def utf8_safe_split(n)
    if length <= n
      [self, nil]
    else
      before = self[0, n]
      after = self[n..-1]
      until after.valid_utf8?
        n = n - 1
        before = self[0, n]
        after = self[n..-1]
      end      
      [before, after.empty? ? nil : after]
    end
  end  
end
class Fixnum
  def prime?
    (self < 2) && (return false)
    i = 2
    j = self
    while (i < j) do
      (self % i == 0) && (return false) 
      i += 1
      j = self / i
    end
    return true
  end
end
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