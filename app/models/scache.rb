# coding: UTF-8

# Salor -- The innovative Point Of Sales Software for your Retail Store
# Copyright (C) 2012-2013  Red (E) Tools LTD
# 
# See license.txt for the license applying to all files within this software.

class Scache
  class << self

    def write(path, output_buffer, &block)
      pos = output_buffer.length
      yield
      output_safe = output_buffer.html_safe?
      fragment = output_buffer.slice!(pos..-1)
      if output_safe
        output_buffer = output_buffer.html_safe
      end
      txt = fragment
      tmp_path = path.split('/')
      tmp_path.pop
      tmp_path = tmp_path.join('/')
      FileUtils.makedirs(tmp_path) unless File.exist?(tmp_path)
      File.atomic_write(path) do |f| 
        f.write(txt)
      end
      return txt
    end

    def keygen(key)
    	return ::Rails.root.to_s + "tmp/cache/views/" + key + ".cache"
    end

    def dofrag(key, allowed_age = 0, output_buffer, &block)
      path = keygen(key)
      if not File.exists?(path) then
        return write(path, output_buffer, &block)
      else
        File.open(path) do |f|
          return f.read
        end
      end
    end

  end
end
