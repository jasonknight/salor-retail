# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'RMagick'

module Escper
  class Image
    def initialize(source, type)
      if type == :file
        @image = Magick::Image.read(source).first
      elsif type == :blob
        @image = Magick::Image.from_blob(source).first
      elsif type == :object
        @image = source
      end
      @x = (@image.columns / 8.0).round
      @y = (@image.rows / 8.0).round
      @x = 1 if @x.zero?
      @y = 1 if @y.zero?
    end

    def convert
      @image = @image.quantize 2, Magick::GRAYColorspace
    end

    def crop
      @image = @image.extent @x * 8, @y * 8
    end

    def to_a
      @image.export_pixels
    end

    def to_s
      self.convert
      self.crop
      colorarray = self.to_a
      bits = []
      mask = 0x80
      i = 0
      temp = 0
      (@x * @y * 8 * 3 * 8).times do |j|
        next unless (j % 3).zero?
        temp |= mask if colorarray[j] == 0 # put 1 in place if black
        mask = mask >> 1
        i += 3
        if i == 24
          bits << temp
          mask = 0x80
          i = 0
          temp = 0
        end
      end
      result = bits.collect{ |b| b.chr }.join
      escpos = "\x1D\x76\x30\x00#{@x.chr}\x00#{(@y*8).chr}\x00#{ result }"
      escpos.force_encoding('ISO-8859-15')
      return escpos
    end
  end
end