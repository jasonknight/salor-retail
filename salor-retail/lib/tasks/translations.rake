# Copyright (c) 2012 Red (E) Tools Ltd.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'yaml'
require 'active_support'
require 'json'

$unused = 0
$source = ''
$target = ''


def find_deprecations(h)
  h.each do |k,v|
    if not h[k].is_a?(Hash) then
      if `grep -ir "#{k}" app/*`.blank? then
        puts "#{k}: doesn't seem to be used."
        $unused += 1
      end
    else
      find_deprecations(h[k])
    end
  end
end

def remove_deprecations(orig_hash)
  new_hash = Hash.new
  orig_hash.each do |key,value|
    if not orig_hash[key].is_a?(Hash) then
      if `grep -ir "#{key}" app/*`.blank? then
        puts "#{key}: doesn't seem to be used."
        $unused += 1
      else
        new_hash[key] = value
      end
    else
      new_hash[key] = remove_deprecations(orig_hash[key])
    end
  end
  return new_hash
end

# this just copies translations from source into target, if they are not existing there
def merge(source,target)
  source.stringify_keys!
  target.stringify_keys!
  source.each do |key,value|
    if not value.is_a? Hash and not target[key] then
      puts "  #{key} not present in target. Copying"
      target[key] = source[key]
    elsif value.is_a? Hash and not target[key] then
      target[key] = value
    elsif value.is_a? Hash and target[key] then
      target[key] = merge(value,target[key])
    end
  end
  return target
end

# this deletes all nodes from target not present in source
def clean(source,target)
  source.stringify_keys!
  target.stringify_keys!
  output = Hash.new
  target.each do |key,value|
    if not value.is_a? Hash and source[key]
      output[key] = value
    elsif value.is_a? Hash and source[key]
      output[key] = clean(source[key],value)
    else
      puts "  Cleaning #{key} from target"
    end
  end
  return output
end

def equalize(source,target)
  cleaned_target = clean(source,target)
  merged_target = merge(source,cleaned_target)
  return merged_target
end

def compare_yaml_hash(cf1, cf2, context = [])
  cf1.each do |key, value|
    unless cf2.key?(key)
      if value.is_a?(Hash)
        format_hash(context, [key], value)
      else
        puts '{{ ' + context.join(' -> ') + ' }} ' + key + ': ' + value
      end
      next
    end
    if value.is_a?(Hash)
      compare_yaml_hash(value, cf2[key], (context << key))  
      next
    end
  end
  context.pop
end

def format_hash(absolute_context, relative_context = [], hash)
  hash.each do |k,v|
    if v.is_a?(Hash)
      format_hash(absolute_context, (relative_context << k), v)
      next
    else
      puts '{{ ' + absolute_context.join(' -> ') + ' -> ' + relative_context.join(' -> ') + ' }} ' + k.to_s + ': ' + v.to_s
    end
  end
end

def returning(value)
  yield(value)
  value
end

def convert_hash_to_ordered_hash_and_sort(object, deep = false)
# from http://seb.box.re/2010/1/15/deep-hash-ordering-with-ruby-1-8/
  if object.is_a?(Hash)
    # Hash is ordered in Ruby 1.9! 
    res = returning(RUBY_VERSION >= '1.9' ? Hash.new : ActiveSupport::OrderedHash.new) do |map|
      object.each {|k, v| map[k] = deep ? convert_hash_to_ordered_hash_and_sort(v, deep) : v }
    end
    return res.class[res.sort {|a, b| a[0].to_s <=> b[0].to_s } ]
  elsif deep && object.is_a?(Array)
    array = Array.new
    object.each_with_index {|v, i| array[i] = convert_hash_to_ordered_hash_and_sort(v, deep) }
    return array
  else
    return object
  end
end

def open_translation(s, t)
  sourcefile = File.join(Rails.root,'config','locales',s)
  source = YAML.load_file sourcefile
  sourcelang = source.keys.first
  source = source[sourcelang]
  
  transfile = File.join(Rails.root,'config','locales',t)
  translation = YAML.load_file transfile
  translationlang = translation.keys.first
  translation = translation[translationlang]
  return source, sourcelang, sourcefile, translation, translationlang, transfile
end

def write_translation(translation, translationlang, transfile)
  output_translation = Hash.new
  output_translation[translationlang] = translation
  File.open(transfile,'w'){ |f| f.write output_translation.to_yaml }
end

def write_javascript_i18n
  YAML::ENGINE.yamler = 'syck'
  yaml_root = File.join(Rails.root, 'config', 'locales')
  js_root = File.join(Rails.root, 'public', 'jslocales')
  js_namespace = 'i18n = '
  
  Dir[File.join(yaml_root, 'main.*.yml')].sort.each do |locale| 
    locale_yml = YAML::load(IO.read(locale))
    File.open(File.join(js_root, File.basename(locale, '.*') + '.js'), 'w') do |f| 
      tmp = locale_yml[File.basename(locale, '.*').split('.')[1]]
      final = {}
      tmp.each do |k,v|
        final[k] = v if not [:time,:date].include? k.to_sym
      end
      f.write(js_namespace + final.to_json)
    end
  end

  js_namespace = 'Region = '
  Dir[File.join(yaml_root, 'region.*.yml')].sort.each do |locale| 
    locale_yml = YAML::load(IO.read(locale))
    File.open(File.join(js_root, File.basename(locale, '.*') + '.js'), 'w') do |f| 
      tmp = locale_yml[File.basename(locale, '.*').split('.')[1]]
      final = {}
      tmp.each do |k,v|
        final[k] = v if not [:time,:date].include? k.to_sym
      end
      f.write(js_namespace + final.to_json)
    end
  end
end

namespace :translations do
  # usage: rake translations:compare_locales['main.gn.yml','main.pl.yml']
  desc "Compare locales" 
  task :compare, :sourcefile, :transfile do |t, args|
    sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
    source = YAML.load_file sourcefile
    sourcelang = source.keys.first
    source = source[sourcelang]
  
    transfile = File.join(Rails.root,'config','locales',args[:transfile])
    translation = YAML.load_file transfile
    translationlang = translation.keys.first
    translation = translation[translationlang]
  
    puts ''
    puts "============== ADD TO FILE #{ args[:transfile] } ============"
    puts ''
    compare_yaml_hash(source, translation, [translationlang])
  
    puts ''
    puts "=========== REMOVE FROM FILE #{ args[:transfile] } =========="
    puts ''
    compare_yaml_hash(translation, source, [translationlang])
  
  
  #   sourceordered = convert_hash_to_ordered_hash_and_sort(source, true)
  #   output_source = Hash.new
  #   output_source[sourcelang] = sourceordered
  # 
  #   translationordered = convert_hash_to_ordered_hash_and_sort(translation, true)
  #   output_translation = Hash.new
  #   output_translation[translationlang] = translationordered
  # 
  #   File.open(sourcefile,'w'){ |f| f.write output_source.to_yaml }
  #   File.open(transfile,'w'){ |f| f.write output_translation.to_yaml }
  
  end
  
  # usage: rake translations:merge['main.gn.yml','main.pl.yml']
  task :merge, :sourcefile, :transfile do |t,args|
    puts "Merging #{args[:sourcefile]} -> #{args[:transfile]}...\n"
    source, sourcelang, sourcefile, translation, translationlang, transfile = open_translation(args[:sourcefile], args[:transfile])
    translation = merge(source,translation)
    write_translation(translation, translationlang, transfile)
  end
  
  # usage: rake translations:clean['main.gn.yml','main.pl.yml']
  task :clean, :sourcefile, :transfile do |t,args|
    puts "Cleaning #{args[:sourcefile]} -> #{args[:transfile]}...\n"
    source, sourcelang, sourcefile, translation, translationlang, transfile = open_translation(args[:sourcefile], args[:transfile])
    translation = clean(source,translation)
    write_translation(translation, translationlang, transfile)
  end

  # usage: rake translations:equalize['main.gn.yml','main.pl.yml']
  task :equalize, :sourcefile, :transfile do |t,args|
    puts "Equalizing #{args[:sourcefile]} -> #{args[:transfile]}...\n"
    source, sourcelang, sourcefile, translation, translationlang, transfile = open_translation(args[:sourcefile], args[:transfile])
    translation = equalize(source,translation)
    write_translation(translation, translationlang, transfile)
  end
  
  # usage: rake translations:order['main.gn.yml']
  task :order, :sourcefile do |t,args|
    puts "Sorting #{ args.inspect }...\n"
    sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
    source = YAML.load_file sourcefile
    sourcelang = source.keys.first
    source = source[sourcelang]
    sourceordered = convert_hash_to_ordered_hash_and_sort(source, true)
    output_source = Hash.new
    output_source[sourcelang] = sourceordered
    File.open(sourcefile,'w'){ |f| f.write output_source.to_yaml }
  end
  
  # usage: rake translations:find_deprecations['main.gn.yml']
  task :find_deprecations, :sourcefile do |t,args|
    puts "Finding deprecations...\n"
    sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
    source = YAML.load_file sourcefile
    sourcelang = source.keys.first
    source = source[sourcelang]
    find_deprecations(source)
    puts "#{$unused} keys found."
  end
  
  # usage: rake translations:remove_deprecations['main.gn.yml']
  task :remove_deprecations, :sourcefile do |t,args|
    puts "Removing deprecations...\n"
    sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
    source = YAML.load_file sourcefile
    sourcelang = source.keys.first
    source = source[sourcelang]
    new_hash = remove_deprecations(source)
    output_source = Hash.new
    output_source[sourcelang] = new_hash
    File.open(sourcefile,'w'){ |f| f.write output_source.to_yaml }
    puts "#{$unused} keys found."
  end
  
  # usage: rake translations:update
  task :update do
    base_path = File.join(Rails.root,'config','locales')
    base_name = "main.XXX.yml" # i.e. the pattern name of the files
    langs = ['en','gn','fr','es','ru','it','cn','el','fi']
    default_file = File.join(base_path,base_name.gsub('XXX',langs[0])) #i.e. the first file is the default file
    langs.each do |lang|
      current_file = File.join(base_path,base_name.gsub('XXX',lang))
      if not File.exists? current_file then
        puts "Translation file doesn't exist, copying it..."
        `cp #{default_file} #{current_file}`
      else
        t = base_name.gsub('XXX',lang)
        s = base_name.gsub('XXX',langs[0])
        source, sourcelang, sourcefile, translation, translationlang, transfile = open_translation(s,t)
        puts "  Ordering translation for #{ lang }"
        translation = convert_hash_to_ordered_hash_and_sort(translation, true)
        if sourcelang != translationlang
          puts "\n\nEqualizing #{sourcelang} => #{translationlang}"
          translation = equalize(source,translation)
        end
        write_translation(translation, translationlang, transfile)
      end
    end
    write_javascript_i18n
  end
  
  task :write_i18n_js do
    puts "\n\nWriting translations to JS"
    write_javascript_i18n
  end
end
