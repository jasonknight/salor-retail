class JsApi
  attr_reader :plugin_name, :company, :vendor, :user, :meta

  def initialize(pname,company,vendor,user)
    set_plugin_name(pname)
    set_company(company.attributes)
    set_user(user.attributes)
    @private_user         = user
    @private_vendor       = vendor
    @private_company      = company
    @evaluated = false
  end

  def set_object(o)
    @object = o
  end

  def get_object()
    return @object
  end

  def get_meta(key)
    return @private_user.user_meta.find_or_create_by_key(key).value
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
    cxt = V8::Context.new()
    cxt['api'] = self
    begin
      result = cxt.eval(text)
    rescue => e
      log_action "V8::Error" + e.to_s
    end
    return result
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