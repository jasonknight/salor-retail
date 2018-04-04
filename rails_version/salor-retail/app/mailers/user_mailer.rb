class UserMailer < ActionMailer::Base
  default from: "#{SalorRetail::Application::SR_DEBIAN_SITEID}.sr@#{ `hostname`.strip }"
  
  def technician_message(vendor, subject, msg='', request=nil)
    if request
      @ip = request.remote_ip
      @useragent = request.env['HTTP_USER_AGENT']
    end
    @message = msg
    mail(:to => vendor.technician_email, :subject => "[SalorRetailMessage #{ vendor.name }] #{ subject }") 
  end
end
