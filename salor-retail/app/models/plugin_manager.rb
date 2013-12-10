class PluginManager < AbstractController::Base
  include SalorBase
  include AbstractController::Rendering
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  include Rails.application.routes.url_helpers
  helper ApplicationHelper
  self.view_paths = "app/views/"
  attr_accessor :javascript_files, :stylesheet_files, :image_files, :metas,:logger
  
  def initialize(current_vendor)
    @vendor                 = current_vendor
    @plugins                = @vendor.plugins.visible
    @context                = V8::Context.new
    @context['Salor']       = self
    @context['Params']      = $PARAMS
    @context['Request']     = $REQUEST
    @context['PLUGINS_BASE_URL']         = @vendor.urls[:plugins]
    @code = nil
    @javascript_files = {}
    @stylesheet_files = {}
    @image_files = {}
    @metas = {}
    # Filters are organized by name, which will be an
    # array of filters which will be sorted by their priority
    # { :some_filter => [
    #       {:function => "my_callback"}
    #   ]
    # }
    @filters                = {}
    @hooks                  = {}
    text                    = "(function () {\nvar __plugin__ = null;\nvar plugins = {};\n"
    @plugins.each do |plugin|
        #log_action plugin.filename.current_path
      
      _files = plugin.files
      plugin_file_name = nil
      @metas[self.get_plugin_name(plugin)] = plugin.meta
      _files.each do |f|
        if f.match(/\.pl\.js$/) then
          plugin_file_name = File.join(plugin.full_path,f)
        elsif f.match(/\.js$/) then
          @javascript_files[plugin.name] ||= []
          @javascript_files[plugin.name] << f
        elsif f.match(/\.css$/) then
          @stylesheet_files[plugin.name] ||= []
          @stylesheet_files[plugin.name] << f
        elsif f.match(/\.svg$/) then
          @image_files[plugin.name] ||= []
          @image_files[plugin.name] << f
        end
      end
      
      if plugin_file_name and File.exists? plugin_file_name
        begin
          log_action("Opening plugin file " + plugin_file_name)
          File.open(plugin_file_name,'r') do |f|
          text += "\n__plugin__ = #{plugin.attributes.to_json};\n";
          text += f.read
         end
        rescue => e
          log_action("There was an error")
          log_action e.inspect
        end
      end
    end
    text += "return plugins; \n})();\n"
    begin
      #log_action("Code is: " + text)
      @code = @context.eval(text)
    rescue => e
      log_action "Code failed to evaluate"
      log_action e.inspect
    end
  end
  
  def log_action_plugin(txt="",color=:grey_on_red)
    from = self.class.to_s
    SalorBase.log_action(from, "PLUGIN: #{ txt }", color)
  end
  
  
  def get_icon_for(plugin)
    if @image_files[self.get_plugin_name(plugin)] and @image_files[self.get_plugin_name(plugin)].any? then
      @image_files[self.get_plugin_name(plugin)].each do |img|
        if img.match(/icon\.svg$/) then
          return "#{plugin.full_url}/#{img}"
        end
      end
    end
    return ''
  end
  def get_plugin_name(plugin)
    plugin.files.each do |f|
      if f.match(/\.pl\.js$/) then
        name = File.basename(f).gsub(".pl.js",'')
        return name
      end
    end
    return ''
  end
  def get_meta_fields_for(plugin)
      fields = {}
      fields = apply_filter('plugin_meta_fields_for_' + self.get_plugin_name(plugin),fields)
    return fields;
  end
  def debug_obj(obj) 
    obj.each do |k,v|
      puts k.inspect
      log_action "#{k} -> #{v}"   
    end
  end
  def priority_sort(arr)
    return arr.sort {|a,b|  b[:priority] <=> a[:priority]}
  end
  def add_filter(name,function, priority=0)
    @filters[name.to_sym] ||= []
    @filters[name.to_sym].push({:function => function, :priority => priority})
    @filters[name.to_sym] = priority_sort(@filters[name.to_sym])
  end

  def add_hook(name,function,priority=0)
    @hooks[name.to_sym] ||= []
    @hooks[name.to_sym].push({:function => function, :priority => priority})
    @hooks[name.to_sym] = priority_sort(@hooks[name.to_sym])
  end

  def get_function_from(obj,path)

    if path.include? '.' then
      # I.E. The namespacing will be like this
      # my.obj.callback
      # so we split by . then reverse, then pop
      # then drill down to the callback function
      path = path.split('.').reverse
      first = path.pop
      function = obj[first]
      path.each do |fname|
        function = function[fname]
      end
    else
      function = obj[path]
    end
    return function

  end

  # Filters work more or less in the same way as WP.
  # You pass in an argument and run it through the filters
  # and then it is returned to you.
  def apply_filter(name,arg)
    log_action("Applying filter: " + name)
    return arg if not @code
    cvrt = nil
    cvrt = arg.class
    if @filters[name.to_sym] then
      @filters[name.to_sym].each do |callback|
        begin
          function_name = callback[:function]
          
          function = get_function_from(@code,function_name)
          
          if not function then
            log_action "function #{callback[:function]} is not set."
          else
            arg = function.methodcall(function,arg)
          end
          
         rescue => e
           log_action "When Applying Filter" + e.inspect
        end
      end 
    end
    if cvrt == Array then
      narg = []
      arg.each do |el|
        if el.is_a? V8::Object then
          el = v8_object_to_hash(el)
        end
        narg << el
      end
      arg = narg
    elsif cvrt == Hash then
      arg = v8_object_to_hash(arg)
    end
    log_action("Filter #{name} done.")
    return arg

  end

  def do_hook(name)
    name = name.to_s
    log_action("Beginning HOOK " + name)
    return '' if not @code
    content = ''
    if @hooks[name.to_sym] then
      @hooks[name.to_sym].each do |callback|
        log_action("Executing HOOK " + name)
        begin
          function_name = callback[:function]
          
          function = get_function_from(@code,function_name)
          
          if not function then
            log_action "function #{callback[:function]} is not set."
          else
            log_action("About to call HOOK " + name)
            begin
              tmp = function.methodcall(function)
            rescue => e
              log_action("There was an error in the HOOK " + name + ": " + e.inspect)
              log_action e.backtrace.join("\n")
            end
            log_action("Call to HOOK " + name + " completed")
            if tmp.nil? then
              log_action "Must return a string from a hook"
            else
              log_action("HOOK returned: " + tmp)
              content += tmp
            end
          end
          
         rescue => e
           log_action "When doing hook" + e.inspect
           log_action e.backtrace.join("\n")
        end
      end 
    else
      log_action("There are no HOOKs")
    end
    log_action("HOOK COMPLETE")
    return content.html_safe

  end

  def render_partial(name,locals)
    vars = v8_object_to_hash(locals)
    debug_obj(vars)
    render( :partial => name, :locals => vars)
  end

  def v8_object_to_hash(src_attrs)
    attrs = {}
    log_action "Trying to convert to hash"
    if src_attrs.kind_of? V8::Object then
      src_attrs.each do |k,v|
        k.gsub("'",'').gsub('"','')
        if v.kind_of? V8::Object then
          attrs[k.to_sym] = v8_object_to_hash(v)
        else
          attrs[k.to_sym] = v
        end
      end
    end
    log_action("Hash converted to " + attrs.inspect )
    return attrs
  end

end