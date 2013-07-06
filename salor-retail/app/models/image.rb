# coding: UTF-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'RMagick'

class Image < ActiveRecord::Base
  include Scope
  belongs_to :imageable, :polymorphic => true
  belongs_to :vendor
  belongs_to :company
  after_save :process
	after_destroy :cleanup
  
  validate :is_valid_upload
  
	DIRECTORY = File.join('public','uploads',SalorHospitality::Application::SH_DEBIAN_SITEID,'images')
	THUMB_MAX_SIZE = [90,90]
  LARGE_MAX_SIZE = [800,800]
	VERSIONS = ['original','thumb','large']
	IMAGE_QUALITY = 80
  MAX_IMAGE_UPLOAD_SIZE = 500.kilobytes
  VALID_IMAGE_TYPES = ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/bmp']
  
  def image
    large_url
  end

  def thumb
    thumbnail_url
  end

	def parse_filename(filename, model)
    xt = filename.split('.').last.downcase.gsub(/(jpeg|bmp)/,'jpg')
		fn = filename.gsub('.'+xt,'').gsub(/[^[:alnum:]]/,'_').gsub(/\s+/,'_').gsub(/_{2,}/,'_').to(59)
		write_attribute 'name', "#{fn}.#{xt}"
		#write_attribute 'model', model
		return "#{fn}.#{xt}"
	end

	def file_data=(file)
    @file_data = file
    parse_filename(@file_data.original_filename.split('\\').last.split('/').last, file.class.to_s)
	end

	def versions
		VERSIONS
	end

	def thumbnail_url
		thumbnail_path.sub(/^public/,'')
	end

	def large_url
		large_path.sub(/^public/,'')
	end

	def sub_dir
		tsubdir = (self.id.to_i/20000).floor
    tsubdir = 0 if tsubdir < 0
    return tsubdir
	end

  def make_path(path)
    identifier = "unknown"
    #ActiveRecord::Base.logger.info "Image::make_path: self is #{ self.inspect }, self.company is #{ self.company.inspect }"
    identifier = self.company.identifier if self.company and self.company.identifier and not self.company.identifier.empty?
    path = File.join(DIRECTORY, identifier, "s#{sub_dir}", "#{self.id}","#{path}","#{name}")
    return path
  end

	def original_path
		make_path("original")
	end

	def thumbnail_path
		make_path("thumb")
	end

	def large_path
		make_path("large")
	end

	def self.destroy_nulls
		imgs = Image.find(:all, :conditions => 'name is NULL')
		imgs.each do |thisimg|
      thisimg.destroy
		end unless imgs.nil?
	end

	def is_valid_upload
		return true if self.name.blank?
		errors.add(":", I18n.t(:"images.errempty")) if @file_data.blank?
		errors.add(":", I18n.t(:"images.errsize")) if @file_data.size == 0 or @file_data.size > MAX_IMAGE_UPLOAD_SIZE
    errors.add(":", I18n.t(:"images.errtype")) unless @file_data.original_filename.split('\\').last.split('/').last.split('.').last.match(/jpg|jpeg|gif|png|bmp/i) and VALID_IMAGE_TYPES.include? @file_data.content_type.chomp
	end

	def process    
		if @file_data
      
      belongsto_class = self.imageable_type.constantize
      parent_model = belongsto_class.find_by_id(self.imageable_id) if belongsto_class
      company = parent_model.company if parent_model
      write_attribute :company_id, company.id
      
      
      # Delete existing image dirs
      VERSIONS.each { |ver| FileUtils.rm_rf(get_path(ver)) if File.exists?(get_path(ver)) and get_path(ver) != 'original' }
			create_directory('original')
      # Save temp file
      @file_data.rewind
      file = File.open(original_path,'wb')
      file.puts @file_data.read
      file.close

      create_resized('large', LARGE_MAX_SIZE, original_path, large_path)
      create_resized('thumb', THUMB_MAX_SIZE, original_path, thumbnail_path)
			@file_data = nil
      # Delete temp folder
      FileUtils.rm_rf(get_path('original')) if File.exists?(get_path('original'))
		end
    Image.destroy_nulls
	end

	def get_resize_ratio(pic, dimensions)
		maxwidth = dimensions[0]
    maxheight = dimensions[1]
		imgwidth = pic.columns
		imgheight = pic.rows
		if imgwidth < maxwidth and imgheight < maxheight then
			scaleratio = 1
		else
			aspectratio = maxwidth.to_f / maxheight.to_f
			imgratio = imgwidth.to_f / imgheight.to_f
			imgratio > aspectratio ? scaleratio = maxwidth.to_f / imgwidth : scaleratio = maxheight.to_f / imgheight
		end
		return scaleratio
	end

	def create_resized(type, dimensions, orig_path, target_path)
		img = Magick::Image.read(orig_path).first
		smartratio = get_resize_ratio(img, dimensions)
		sm_image = img.thumbnail(smartratio)
		create_directory(type)
		sm_image.write(target_path) { self.quality = IMAGE_QUALITY }
	end

	def get_path(type=nil)
    identifier = "unknown"
    identifier = self.company.identifier if self.company and self.company.identifier and not self.company.identifier.empty?
		if type.nil? or type.empty? then
			File.join(DIRECTORY, identifier, "s#{sub_dir}", "#{self.id}")
		else
			File.join(DIRECTORY, identifier, "s#{sub_dir}", "#{self.id}", type.to_s)
		end
	end

	def create_directory(type)
		FileUtils.mkdir_p get_path(type)
	end

	def cleanup
    identifier = "unknown"
    identifier = self.company.identifier if self.company and self.company.identifier and not self.company.identifier.empty?
		unless self.id.nil?
      ipath = File.join(DIRECTORY, identifier, "s#{sub_dir}", "#{self.id}")
      FileUtils.rm_rf(ipath) if File.exists?(ipath)
		end
	end

end
