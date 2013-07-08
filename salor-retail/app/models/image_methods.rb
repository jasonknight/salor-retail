# coding: UTF-8

# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ImageMethods
  def image(typ=nil)
    if typ.nil? then
      return self.images.first.image if self.images.first and self.images.first.id
    else
      tmp = self.images.where(:image_type => typ).first
      return tmp.image if tmp and tmp.id
    end
    return File.join("/assets", "empty.png")
  end

  def thumb(typ=nil)
    if typ.nil? then
      return self.images.first.thumb if self.images.first and self.images.first.id
    else
      tmp = self.images.where(:image_type => typ).first
      return tmp.thumb if tmp and tmp.id
    end
    return File.join("/assets", "empty.png")    
  end
end
