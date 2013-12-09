require 'fileutils'
require 'zip/zipfilesystem'
require 'json'

class Plugin < ActiveRecord::Base
  include SalorScope
  include SalorBase
  before_create :maybe_unzip
  before_update :maybe_unzip
  
  belongs_to :company
  belongs_to :vendor
  serialize :meta
  
  validates_presence_of :vendor_id, :company_id

  mount_uploader :filename, PluginUploader # see app/uploaders This is done with CarrierWave
  
  def _wipe(entry)
    if Dir.exists?(entry)
        log_action("Dir Exists, removing " + entry)
        FileUtils.rm_rf(entry)
    end
    if File.exists?(entry) then
        log_action("File exists, removing " + entry)
        FileUtils.rm_f(entry)
    end
    log_action("Wiped for " + entry)
  end
  
  def write_file(zf,path)
    log_action("Writing file: " + path)
    File.open(path,"w+") do |f|
        f.write zf.get_input_stream.read
    end
    if not File.exists? path then
        log_action( "File: " + path + " could not be created!")
        raise "File: " + path + " could not be created!"
    else
        log_action(" Ruby says the file exists!!")
    end
  end
  
  def maybe_unzip
    path = self.filename.current_path
    _files = []
    if path.match(/\.zip$/) then
        wiped = false
        Zip::ZipFile.foreach(path) do |file|
            if wiped == false then
                _wipe(File.join( $DIRS[:stylesheets],File.dirname(file.name) ))
                wiped = true
            end
            if file.name.match(/\.svg$/) then
                log_action("It's an svg! " + file.name)
                FileUtils.mkdir_p( File.join( $DIRS[:images],File.dirname(file.name) ) )
                write_file(file,File.join( $DIRS[:images],file.name ))
                _files << file.name
                
            elsif file.name.match(/\.pl\.js/) then
                log_action("It's the main plugin file " + file.name)
                FileUtils.mkdir_p( File.join( $DIRS[:plugins],File.dirname(file.name) ) )
                write_file(file,File.join( $DIRS[:plugins],file.name ))
                _files << file.name
            elsif file.name.match(/\.js$/) then
                log_action("It's a js file" + file.name)
                FileUtils.mkdir_p( File.join( $DIRS[:javascripts],File.dirname(file.name) ) )
                write_file(file,File.join( $DIRS[:javascripts],file.name ))
                _files << file.name
            elsif file.name.match(/\.css$/) then
                log_action("It's a css file" + file.name)
                
                FileUtils.mkdir_p( File.join( $DIRS[:stylesheets],File.dirname(file.name) ) )
                write_file(file,File.join( $DIRS[:stylesheets],file.name ))
                _files << file.name
            end
        end
    end
    log_action("Setting files to " + _files.inspect)
    self.files = _files
  end
  
  def files=(list)
    _list = list.to_json
    log_action("About to save: " + _list)
    write_attribute(:files, _list)
  end

  def files
    _list = read_attribute(:files)
    log_action("I read: " + _list.inspect)
    if _list then
        return JSON.parse(_list)
    else
        return []
    end
  end
end
