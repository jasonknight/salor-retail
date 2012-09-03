require 'action_dispatch/middleware/show_exceptions'
module ActionDispatch
  class ShowExceptions
    private
      def render_exception_with_template(env, exception)
        body = ErrorsController.action(:errors_display).call(env)
        log_error(exception)
        body
      rescue
        render_exception_without_template(env, exception)
      end
      alias_method_chain :render_exception, :template
  end
end


