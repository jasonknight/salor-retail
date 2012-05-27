require 'yaml'
require 'active_support'
$unused = 0
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
def merge(source,target)
  source.stringify_keys!
  target.stringify_keys!
  source.each do |key,value|
    if not value.is_a? Hash and not target[key] then
      puts "#{key} not present in target."
      target[key] = "XXX " + source[key]
    elsif value.is_a? Hash and target[key] then
      target[key] = merge(value,target[key])
    end
  end
  return target
end
def compare_yaml_hash(cf1, cf2, context = [])
  cf1.each do |key, value|
    unless cf2.key?(key)
      unless value.is_a?(Hash)
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


# usage: rake compare_locales['billgastro_gn.yml','billgastro_pl.yml']
desc "Compare locales" 
task :compare_locales, :sourcefile, :transfile do |t, args|
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
task :merge_translations, :sourcefile,:transfile do |t,args|
  sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
  source = YAML.load_file sourcefile
  sourcelang = source.keys.first
  source = source[sourcelang]
  
  transfile = File.join(Rails.root,'config','locales',args[:transfile])
  translation = YAML.load_file transfile
  translationlang = translation.keys.first
  translation = translation[translationlang]
  
  translation = merge(source,translation)
  
  output_translation = Hash.new
  output_translation[translationlang] = translation
  File.open(transfile,'w'){ |f| f.write output_translation.to_yaml }
end
task :order_translation, :sourcefile do |t,args|
  sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
  source = YAML.load_file sourcefile
  sourcelang = source.keys.first
  source = source[sourcelang]
  sourceordered = convert_hash_to_ordered_hash_and_sort(source, true)
  output_source = Hash.new
  output_source[sourcelang] = sourceordered
  File.open(sourcefile,'w'){ |f| f.write output_source.to_yaml }
end
task :find_deprecations, :sourcefile do |t,args|
  sourcefile = File.join(Rails.root,'config','locales',args[:sourcefile])
  source = YAML.load_file sourcefile
  sourcelang = source.keys.first
  source = source[sourcelang]
  find_deprecations(source)
  puts "#{$unused} keys found."
end
task :remove_deprecations, :sourcefile do |t,args|
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
task :fix_translations do
  base_path = File.join(Rails.root,'config','locales')
  base_name = "salor.XXX.yml" # i.e. the pattern name of the files
  langs = ["en-US","en-GB","de","fr","es","fi","cn","tr","pl","ru"]
  default_file = File.join(base_path,base_name.gsub('XXX',langs[0])) #i.e. the first file is the default file
  langs.each do |lang|
    current_file = File.join(base_path,base_name.gsub('XXX',lang))
    puts "Current File is: #{current_file}"
    if not File.exists? current_file then
      `cp #{default_file} #{current_file}`
    else
      puts "Merging translations for #{base_name.gsub('XXX',lang)}"
      `rake merge_translations['#{base_name.gsub('XXX',langs[0])}','#{base_name.gsub('XXX',lang)}']`
      puts "File exists, ordering"
      `rake order_translation['#{base_name.gsub('XXX',lang)}']`
#       `rake remove_deprecations['#{base_name.gsub('XXX',lang)}']`
    end
  end
end
