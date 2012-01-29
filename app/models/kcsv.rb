# ------------------- Salor Point of Sale ----------------------- 
# An innovative multi-user, multi-store application for managing
# small to medium sized retail stores.
# Copyright (C) 2011-2012  Jason Martin <jason@jolierouge.net>
# Visit us on the web at http://salorpos.com
# 
# This program is commercial software (All provided plugins, source code, 
# compiled bytecode and configuration files, hereby referred to as the software). 
# You may not in any way modify the software, nor use any part of it in a 
# derivative work.
# 
# You are hereby granted the permission to use this software only on the system 
# (the particular hardware configuration including monitor, server, and all hardware 
# peripherals, hereby referred to as the system) which it was installed upon by a duly 
# appointed representative of Salor, or on the system whose ownership was lawfully 
# transferred to you by a legal owner (a person, company, or legal entity who is licensed 
# to own this system and software as per this license). 
#
# You are hereby granted the permission to interface with this software and
# interact with the user data (Contents of the Database) contained in this software.
#
# You are hereby granted permission to export the user data contained in this software,
# and use that data any way that you see fit.
#
# You are hereby granted the right to resell this software only when all of these conditions are met:
#   1. You have not modified the source code, or compiled code in any way, nor induced, encouraged, 
#      or compensated a third party to modify the source code, or compiled code.
#   2. You have purchased this system from a legal owner.
#   3. You are selling the hardware system and peripherals along with the software. They may not be sold
#      separately under any circumstances.
#   4. You have not copied the software, and maintain no sourcecode backups or copies.
#   5. You did not install, or induce, encourage, or compensate a third party not permitted to install 
#      this software on the device being sold.
#   6. You have obtained written permission from Salor to transfer ownership of the software and system.
#
# YOU MAY NOT, UNDER ANY CIRCUMSTANCES
#   1. Transmit any part of the software via any telecommunications medium to another system.
#   2. Transmit any part of the software via a hardware peripheral, such as, but not limited to,
#      USB Pendrive, or external storage medium, Bluetooth, or SSD device.
#   3. Provide the software, in whole, or in part, to any thrid party unless you are exercising your
#      rights to resell a lawfully purchased system as detailed above.
#
# All other rights are reserved, and may be granted only with direct written permission from Salor. By using
# this software, you agree to adhere to the rights, terms, and stipulations as detailed above in this license, 
# and you further agree to seek to clarify any right not directly spelled out herein. Any right, not directly 
# covered by this license is assumed to be reserved by Salor, and you agree to contact an official Salor repre-
# sentative to clarify any rights that you infer from this license or believe you will need for the proper 
# functioning of your business.
class Kcsv
	def initialize(file, options)
		@file = file
		@options = options
    @separator = options[:separator]
		options[:header] == true ? @headers = parse_header_line : @headers = false
		@children = []
		
		@accepted_headers = options[:accepted_headers]
		parse
	end
	
	def parse
		i = 0
		@file.rewind
		
		@file.each_line do |line|
			#looping through each line of the file
			if i > 0 then # we are past the first line
				x = 0 #we set the index for our position in the headers.
				row = {} #the row
				if not line.include?(@separator) then #Here we check to see if it is a single column
					row[@headers[x][0]] = clean(line) if not @headers[x].nil?
					row[x] = clean(line) if @headers[x].nil?
				else #we have multiple columns
					line.split(@separator).each do |column|
						#now we need to know if we have headers
						if !@headers.nil? then
								row[@headers[x][0]] = clean(column) if not @headers[x].nil?
						else
							row[x] = clean(column)
						end
						x = x + 1
					end
				end
				@children << row
			else
				i = i + 1 #just there to skipp the first line
			end
		end
		return true
	end
	
	def to_a
		@children
	end
	
	protected
	def clean(string)
		string = string.gsub('"','').strip
    return string
	end
	def parse_header_line
		headers = []
		accepted_headers = @accepted_headers
		@file.rewind
		@file.each_line do |line|
			x = 0
      # puts @separator
			if not line.include?(@separator) then
				headers << [clean(line),x]
				#headers << [x,x] if not accepted_headers.include? clean(line)
			else
				line.split(@separator).each do |col|
					headers << [clean(col).strip,x]
					x = x + 1
				end
			end
			break
		end
		return headers
	end
end
