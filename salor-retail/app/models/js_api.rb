class JsApi
  attr_reader :plugin_name, :company, :vendor, :user, :meta

  def initialize(pname,company,vendor,user,secret)
    set_plugin_name(pname)
    set_company(company.attributes)
    set_user(user.attributes)
    @private_user         = user
    @private_vendor       = vendor
    @private_company      = company
    @evaluated = false
    @secret = secret # to prevent api users from accessing some functions
    @writeable = true
  end

  def set_writeable(secr=nil,bool)
    return if not secr == @secret
    @writeable = bool
  end
  def set_object(o)
    @object = o if not @object
  end

  def get_object(secr=nil)
    if secr == @secret then
      return @object
    else
      return nil
    end
  end

  def get_meta(key)
    return @private_user.user_meta.find_or_create_by_key(key).value
  end
  
  # Api for manipulating objects

  def update_attributes(src_attrs)
    return false if @writeable == false
    attrs = {}
    if src_attrs.kind_of? V8::Object then
      src_attrs.each do |k,v|
        attrs[k] = v
      end
    end
    if @object then
      attrs = attrs.delete_if {|k,v| [:password,:id,:sku].include? k.to_sym }
      begin
        if @object.kind_of? ActiveRecord::Base then
          if @object.update_attributes(attrs) then
            return true
          else
            return false
          end
        elsif @object.kind_of? Hash then
          attrs.each {|k,v| @object[k] = v}
        end
        return true
      rescue
        return false
      end
    else
      return nil
    end
  end

  def set_meta(key, value)
    if value.class == String then
      meta = @private_user.user_meta.find_or_create_by_key(key)
      meta.update_attribute :value, value
    else
      log_action "Cannot set non-string value. JSON encode it if you need to save something complex."
    end
  end
  
  def log_action(msg)
    SalorBase.log_action "Plugin: #{@plugin_name}", msg
  end

  def evaluate_script(text)
    return if @evaluated
    @evaluated = true
    @cxt = V8::Context.new()
    @cxt['api'] = self
    begin
      result = @cxt.eval(text)
    rescue => e
      log_action "V8::Error" + e.to_s
    end
    return result
  end

  def call_function(name, args = {})
    return @cxt.eval("#{name}(#{args.to_json})")
  end

  private

  def set_plugin_name(name)
    if not @plugin_name then
      @plugin_name = name
    end
  end

  def set_user(user_attribs)
    whitelist = [:first_name, :last_name, :language, :theme, :username]
    user_attribs = user_attribs.delete_if {|k,v| ! whitelist.include?(k) }
    @user = user_attribs if not @user
  end

  def set_company(company_attribs)
    @company = company_attribs if not @company
  end

  def set_vendor(vendor_attribs)
    @vendor = vendor_attribs if not @vendor
  end

  

end