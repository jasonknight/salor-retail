<% @text = raw(I18n.t("#{GlobaleData.base_locale}.#{params[:key]}",:locale => :help))  %>
var text = '';
<% splitted = @text.split("\n")  %>
<% if splitted then  %>
  <% @text.split("\n").each do |line|  %>
    text = text + "<%= raw line %>";
  <% end %>
<% else  %>
text = "<%= raw @text %>";
<% end %>
$('.help').html(text);
$('.help').show();
