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
  include SalorScope
  belongs_to :imageable, :polymorphic => true
  belongs_to :vendor
  belongs_to :company

  validate :is_valid_upload
  #validates_presence_of :vendor_id, :company_id
  
  before_save :associate
  after_save :process
  after_destroy :cleanup

  DIRECTORY = File.join('public', 'uploads', SalorRetail::Application::SR_DEBIAN_SITEID)
  THUMB_MAX_SIZE = [90,90]
  LARGE_MAX_SIZE = [800,800]
  VERSIONS = ['original','thumb','large']
  IMAGE_QUALITY = 80
  MAX_IMAGE_UPLOAD_SIZE = 500.kilobytes
  VALID_IMAGE_TYPES = ['image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/bmp']
  
  
  #README
  # 1. The rails way would lead to many duplications
  # 2. The rails way would require us to reorganize all the translation files
  # 3. The rails way in this case is admittedly limited, by their own docs, and they suggest you implement your own
  # 4. Therefore, don't remove this code.
  def self.human_attribute_name(attrib, options={})
    begin
      trans = I18n.t("activerecord.attributes.#{attrib.downcase}", :raise => true) 
      return trans
    rescue
      SalorBase.log_action self.class, "trans error raised for activerecord.attributes.#{attrib} with locale: #{I18n.locale}"
      return super
    end
  end
  
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

  def original_path
    plot_path("original")
  end

  def thumbnail_path
    plot_path("thumb")
  end

  def large_path
    plot_path("large")
  end

  def plot_dir(size)
    File.dirname plot_path(size)
  end

  def plot_path(size)
    hash_id = "unknown"
    hash_id = self.vendor.hash_id if self.vendor and not self.vendor.hash_id.blank?
    path = File.join(DIRECTORY, hash_id, "images", "s#{sub_dir}", "#{self.id}","#{size}","#{self.name}")
    return path
  end

  def sub_dir
    (self.id/1000).floor
  end


  def is_valid_upload
    return true if self.name.blank? or @file_data.blank?
    errors.add(":", I18n.t(:"images.errsize")) if @file_data.size == 0 or @file_data.size > MAX_IMAGE_UPLOAD_SIZE
    errors.add(":", I18n.t(:"images.errtype")) unless @file_data.original_filename.split('\\').last.split('/').last.split('.').last.match(/jpg|jpeg|gif|png|bmp/i) and VALID_IMAGE_TYPES.include? @file_data.content_type.chomp
  end

  def associate
    belongsto_class = self.imageable_type.constantize
    belongsto_model = belongsto_class.find_by_id(self.imageable_id) if belongsto_class

    if belongsto_class == Vendor
      company = belongsto_model.company
      vendor = belongsto_model
    else
      company = belongsto_model.company
      vendor = belongsto_model.vendor
    end

    write_attribute :company_id, company.id
    write_attribute :vendor_id, vendor.id
  end



  def process
    if @file_data
      # Delete existing image dirs
      
      VERSIONS.each { |ver| FileUtils.rm_rf(plot_dir(ver)) if File.exists?(plot_dir(ver)) }
      create_directory('original')
      # Save temp file
      @file_data.rewind
      file = File.open(self.original_path,'wb')
      file.puts @file_data.read
      file.close

      create_resized('large', LARGE_MAX_SIZE, original_path, large_path)
      create_resized('thumb', THUMB_MAX_SIZE, original_path, thumbnail_path)
      @file_data = nil
      # Delete temp folder
      FileUtils.rm_rf(plot_dir('original')) if File.exists?(plot_dir('original'))
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

  def create_directory(size)
    FileUtils.mkdir_p plot_dir(size)
  end

  def cleanup
    hash_id = "unknown"
    hash_id = self.vendor.hash_id if self.vendor and not self.vendor.hash_id.blank?
    FileUtils.rm_rf File.join(DIRECTORY, hash_id.gsub('#', ''), "images", "s#{sub_dir}", "#{self.id}")
  end
  
  def self.destroy_nulls
    Image.where(:name => nil).delete_all
  end

end
