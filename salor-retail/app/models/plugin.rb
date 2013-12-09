#require 'fileutils'
require 'zip/zipfilesystem'
require 'json'

class Plugin < ActiveRecord::Base
  include SalorScope
  include SalorBase
  #before_create :maybe_unzip
  #before_update :maybe_unzip
  
  belongs_to :company
  belongs_to :vendor
  serialize :meta
  
  validates_presence_of :vendor_id, :company_id

  #mount_uploader :filename, PluginUploader # see app/uploaders This is done with CarrierWave
  
  def base_path
    return self.vendor.paths[:plugins]
  end
  
  def full_path
    return full_path_zip.gsub(".zip", "")
  end
  
  def full_path_zip
    return File.join(self.base_path, self.filename)
  end
  
  def full_url
    return "#{ self.vendor.urls[:plugins] }/#{ self.name }"
  end
  
  def filename=(data)
    FileUtils.mkdir_p(self.base_path)
    write_attribute :filename, data.original_filename
    write_attribute :name, data.original_filename.gsub(".zip", "")
    f = File.open(self.full_path_zip, "wb")
    f.write(data.read)
    f.close
  end
  
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
  

  
  def unzip
    _files = []
    if self.filename.match(/\.zip$/) then
      wiped = false
      Zip::ZipFile.foreach(self.full_path_zip) do |file|
        
        if wiped == false then
          _wipe(self.full_path)
          FileUtils.mkdir_p(self.full_path)
          wiped = true
        end
        
        #log_action("creating dir " + self.full_path)
        #FileUtils.mkdir_p(self.full_path)
        
        basename = File.basename(file.name)
        target_filepath = File.join(self.full_path, basename)
        
        if basename.match(/\.svg$/) then
          log_action("It's an svg! " + target_filepath)
          write_file(file, target_filepath)
          _files << basename
            
        elsif file.name.match(/\.pl\.js/) then
          log_action("It's the main plugin file " + target_filepath)
          write_file(file, target_filepath)
          _files << basename
          
        elsif file.name.match(/\.js$/) then
          log_action("It's a js file" + target_filepath)
          write_file(file, target_filepath)
          _files << basename
          
        elsif file.name.match(/\.css$/) then
          log_action("It's a css file" + target_filepath)
          write_file(file, target_filepath)
          _files << basename
        end
      end
    end
    log_action("Setting files to " + _files.inspect)
    self.files = _files
    self.save
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
