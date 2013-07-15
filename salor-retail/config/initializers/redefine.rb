# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActionView
  module Helpers
    module NumberHelper
      alias_method :orig_number_to_currency, :number_to_currency 
      alias_method :orig_number_with_precision, :number_with_precision
      alias_method :orig_number_to_percentage, :number_to_percentage
      
      def number_to_currency(arg1, arg2={})
        if @region
          # when called from views
          arg2.merge! :locale => @region
        end
        orig_number_to_currency(arg1, arg2)
      end
      
      def number_with_precision(arg1, arg2={})
        if @region
          # when called from views
          arg2.merge! :locale => @region
        end          
        orig_number_with_precision(arg1, arg2)
      end
      
      def number_to_percentage(arg1, arg2={})
        if @region
          # when called from views
          arg2.merge! :locale => @region
        end
        orig_number_to_percentage(arg1, arg2)
      end
    end
  end
end