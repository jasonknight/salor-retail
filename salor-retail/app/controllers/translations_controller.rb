class TranslationsController < ApplicationController
  
  before_filter :set_up
 
  def index
    render :nothing => true and return unless @origfile and File.exists?(@origfile)
    contents = File.read(@userfile)
    @translation = YAML::load(contents).to_json
  end
  
  def set
    YAML::ENGINE.yamler = 'psych'
    render :nothing => true and return unless @origfile and File.exists?(@origfile)
    contents = File.read(@userfile)
    
    @translation = YAML::load(contents)
    keys = params['k'].split(',')
    @translation.replace_nested_value_by(keys,params['v'])
    
    contents = @translation.to_yaml
    
    File.open(@userfile, 'w'){ |f| f.write contents }
    render :nothing => true
  end
  
  private
  
  def set_up
    return if params['f'].nil? or params['f'].empty?
    @logdir = File.dirname(SalorRetail::Application.config.paths['log'].first)
    @localedir = File.dirname(SalorRetail::Application.config.paths['config/locales'].first)
    
    #@userfile = File.join(@logdir, params['f'])
    @userfile = File.join(@localedir, params['f'])
    @origfile = File.join(@localedir, params['f'])
    
#     puts
#     puts @logdir.inspect
#     puts @userfile
#     puts @localedir
#     puts @origfile
    
    return unless File.exists?(@origfile)
    
    unless File.exists?(@userfile)
      FileUtils.cp(@origfile, @logdir)
    end
  end
end
