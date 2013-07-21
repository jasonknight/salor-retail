# https://github.com/smartinez87/exception_notification v.3.0.0

require 'action_dispatch'

class ExceptionNotifier
  def self.default_ignore_exceptions
    [].tap do |exceptions|
      exceptions << 'ActiveRecord::RecordNotFound'
      exceptions << 'AbstractController::ActionNotFound'
      exceptions << 'ActionController::RoutingError'
    end
  end

  def self.default_ignore_crawlers
    []
  end

  def initialize(app, options = {})
    @app, @options = app, options

    Notifier.default_sender_address       = @options[:sender_address]
    Notifier.default_exception_recipients = @options[:exception_recipients]
    Notifier.default_email_prefix         = @options[:email_prefix]
    Notifier.default_email_format         = @options[:email_format]
    Notifier.default_sections             = @options[:sections]
    Notifier.default_background_sections  = @options[:background_sections]
    Notifier.default_verbose_subject      = @options[:verbose_subject]
    Notifier.default_normalize_subject    = @options[:normalize_subject]
    Notifier.default_smtp_settings        = @options[:smtp_settings]

    #@campfire = CampfireNotifier.new @options[:campfire]

    @options[:ignore_exceptions] ||= self.class.default_ignore_exceptions
    @options[:ignore_crawlers]   ||= self.class.default_ignore_crawlers
    @options[:ignore_if]         ||= lambda { |env, e| false }
  end

  def call(env)
    @app.call(env)
  rescue Exception => exception
    vendor_id = env['rack.session']['vendor_id']
    vendor = Vendor.find_by_id(vendor_id)
    
    options = (env['exception_notifier.options'] ||= Notifier.default_options)
    options.reverse_merge!(@options)
    
    if vendor
      raise exception if vendor.enable_technician_emails == false
      options[:exception_recipients] = vendor.technician_email if vendor.technician_email
      options[:sender_address] = "#{vendor.name.parameterize}@#{ SalorRetail::Application::SR_DEBIAN_SITEID }"
    end

    unless ignored_exception(options[:ignore_exceptions], exception)       ||
           from_crawler(options[:ignore_crawlers], env['HTTP_USER_AGENT']) ||
           conditionally_ignored(options[:ignore_if], env, exception)
      Notifier.exception_notification(env, exception).deliver
      #@campfire.exception_notification(exception)
      env['exception_notifier.delivered'] = true
    end

    raise exception
  end

  private

  def ignored_exception(ignore_array, exception)
    Array.wrap(ignore_array).map(&:to_s).include?(exception.class.name)
  end

  def from_crawler(ignore_array, agent)
    ignore_array.each do |crawler|
      return true if (agent =~ Regexp.new(crawler))
    end unless ignore_array.blank?
    false
  end

  def conditionally_ignored(ignore_proc, env, exception)
    ignore_proc.call(env, exception)
  rescue Exception => ex
    false
  end
  
  class Notifier < ActionMailer::Base
    self.mailer_name = 'exception_notifier'

    #Append application view path to the ExceptionNotifier lookup context.
    self.append_view_path "#{File.dirname(__FILE__)}/views"

    class << self
      attr_writer :default_sender_address
      attr_writer :default_exception_recipients
      attr_writer :default_email_prefix
      attr_writer :default_email_format
      attr_writer :default_sections
      attr_writer :default_background_sections
      attr_writer :default_verbose_subject
      attr_writer :default_normalize_subject
      attr_writer :default_smtp_settings

      def default_sender_address
        @default_sender_address || %("Exception Notifier" <exception.notifier@default.com>)
      end

      def default_exception_recipients
        @default_exception_recipients || []
      end

      def default_email_prefix
        @default_email_prefix || "[ERROR] "
      end

      def default_email_format
        @default_email_format || :text
      end

      def default_sections
        @default_sections || %w(request session environment backtrace)
      end

      def default_background_sections
        @default_background_sections || %w(backtrace data)
      end

      def default_verbose_subject
        @default_verbose_subject.nil? || @default_verbose_subject
      end

      def default_normalize_subject
        @default_normalize_prefix || false
      end

      def default_smtp_settings
        @default_smtp_settings || nil
      end

      def default_options
        { :sender_address => default_sender_address,
          :exception_recipients => default_exception_recipients,
          :email_prefix => default_email_prefix,
          :email_format => default_email_format,
          :sections => default_sections,
          :background_sections => default_background_sections,
          :verbose_subject => default_verbose_subject,
          :normalize_subject => default_normalize_subject,
          :template_path => mailer_name,
          :smtp_settings => default_smtp_settings }
      end

      def normalize_digits(string)
        string.gsub(/[0-9]+/, 'N')
      end
    end

    class MissingController
      def method_missing(*args, &block)
      end
    end

    def exception_notification(env, exception, options={})
      load_custom_views

      @env        = env
      @exception  = exception
      @options    = options.reverse_merge(env['exception_notifier.options'] || {}).reverse_merge(self.class.default_options)
      @kontroller = env['action_controller.instance'] || MissingController.new
      @request    = ActionDispatch::Request.new(env)
      @backtrace  = exception.backtrace ? clean_backtrace(exception) : []
      @sections   = @options[:sections]
      @data       = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
      @sections   = @sections + %w(data) unless @data.empty?
      
      compose_email
    end

    def background_exception_notification(exception, options={})
      load_custom_views

      if @notifier = Rails.application.config.middleware.detect{ |x| x.klass == ExceptionNotifier }
        @options   = options.reverse_merge(@notifier.args.first || {}).reverse_merge(self.class.default_options)
        @exception = exception
        @backtrace = exception.backtrace || []
        @sections  = @options[:background_sections]
        @data      = options[:data] || {}

        compose_email
      end
    end

    private

    def compose_subject
      subject = "#{@options[:email_prefix]}"
      subject << "#{@kontroller.controller_name}##{@kontroller.action_name}" if @kontroller
      subject << " (#{@exception.class})"
      subject << " #{@exception.message.inspect}" if @options[:verbose_subject]
      subject = normalize_digits(subject) if @options[:normalize_subject]
      subject.length > 120 ? subject[0...120] + "..." : subject
    end

    def set_data_variables
      @data.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    def clean_backtrace(exception)
      if Rails.respond_to?(:backtrace_cleaner)
       Rails.backtrace_cleaner.send(:filter, exception.backtrace)
      else
       exception.backtrace
      end
    end

    helper_method :inspect_object

    def inspect_object(object)
      case object
      when Hash, Array
        object.inspect
      when ActionController::Base
        "#{object.controller_name}##{object.action_name}"
      else
        object.to_s
      end
    end

    def html_mail?
      @options[:email_format] == :html
    end

    def compose_email
      set_data_variables
      subject = compose_subject
      name = @env.nil? ? 'background_exception_notification' : 'exception_notification'

      mail = mail(:to => @options[:exception_recipients], :from => @options[:sender_address],
           :subject => subject, :template_name => name) do |format|
        format.text
        format.html if html_mail?
      end
      
      mail.delivery_method.settings.merge!(@options[:smtp_settings]) if @options[:smtp_settings]
      
      mail
    end

    def load_custom_views
      self.prepend_view_path Rails.root.nil? ? "app/views" : "#{Rails.root}/app/views" if defined?(Rails)
    end
  end
end