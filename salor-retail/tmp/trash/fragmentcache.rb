# Constants for atomize
ISFILE = true
ISDIR = false

# Override the key_file_path method to get rid of those damn hash subdirs for frag cache files
ActiveSupport::Cache::FileStore.module_eval do
	def key_file_path(key)
		# resulting path format:
		#		'thingie'						 -> thingie.cache
		#   'cash_drop/admin'    -> cash_drop/adm/admin.cache
		#   'orders/123456/main' -> orders/123/123456/main.cache
		fname = UnicodeUtils.nfkd(key.to_s).gsub(/[^\x00-\x7F]/,'').to_s # no accented chars
		nodes = fname.split('/')
		return File.join(cache_path, "#{fname}.cache") if nodes.length == 2 # key contains "views/" by default
		lnode = nodes.pop
		fname_paths = []
		nodes.each do |tnode|
			fname_paths << tnode
		end
		if fname_paths.last.match(/^[\d]+$/) then
			# add 3-digit subdir
			numdir = fname_paths.pop.to_i
			subdir = (numdir/1000).floor
			fname_paths << subdir.to_s << numdir.to_s
		else
			# add 3-letter subdir
			fname_paths << lnode[0,3]
		end
		File.join(cache_path, *fname_paths, "#{lnode}.cache")
	end
end

