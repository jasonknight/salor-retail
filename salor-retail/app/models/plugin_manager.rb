class PluginManager
	include SalorBase
	def initialize(vendor)
		@vendor = vendor
		@plugins = Plugin.where(:vendor_id => @vendor.id)
		@plugins.each do |plugin|
			log_action plugin.filename.current_path
		end
	end
end