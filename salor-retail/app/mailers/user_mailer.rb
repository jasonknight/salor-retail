class UserMailer < ActionMailer::Base
  default from: "#{SalorRetail::Application::SR_DEBIAN_SITEID}.sr@#{ `hostname`.strip }"
  
  def technician_message(vendor, subject, msg='', request=nil)
    if request
      @ip = request.remote_ip
      @useragent = request.env['HTTP_USER_AGENT']
    end
    @message = msg
    if vendor.is_a?(String) then
    	mail(:to => vendor, :subject => "[SalorRetailMessage] #{ subject }") 
    else
    	mail(:to => vendor.technician_email, :subject => "[SalorRetailMessage #{ vendor.name }] #{ subject }") 
    end
    
  end
end
