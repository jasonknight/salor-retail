	$.userClickF = function(obj) { 
		$(obj.element).click();
		return false;
	}

	$.userValueF = function(obj) { 
		$(obj.element).val(obj.value);
		return false;
	}

	function diferentWay(element, txt){
		$(element).val(txt);
		return false;
	} 