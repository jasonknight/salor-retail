function Round(Number, DecimalPlaces) {
 return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
}

function RoundFixed(Number, DecimalPlaces) {
 return Round(Number, DecimalPlaces).toFixed(DecimalPlaces);
}

function toFloat(str, returnString) {
  /* if (str == '') {return 0.0;}
  if (returnString == null) returnString = false;
  if (typeof str == 'number') {
    return str;
  }
  if (str.match(/\d+\.\d+\,\d+/)) {
   console.log('matched');
    str = str.replace('.','');
  }
  var ac = [0,1,2,3,4,5,6,7,8,9,'.',',','-'];
  var nstr = '';
  for (var i = 0; i < str.length; i++) {
    c = str.charAt(i);
    if (inArray(c,ac)) {
      if (c == ',') {
        nstr = nstr + '.';
      } else {
        nstr = nstr + c;
      }
    }
  }
  return (returnString) ? nstr : parseFloat(nstr); */
  var r = /([\d,\.]+)[,\.](\d{1,2})/g;
  var matches = r.exec(str);
  if (matches) {
    var lpart = matches[1].replace(/[\.,]+/g,'');
    var rpart = matches[2].replace(/[\.,]+/g,'');
    var num = lpart + '.' + rpart;
  } else {
    num = parseFloat(str);
  }
  
  if (returnString) {
    return num;
  } else {
    num = parseFloat(num);
    if (num+'' == 'NaN') {
      return 0.0;
    } else {
      return num;
    }
  }
}

function roundNumber(num, dec) {
  var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
  return result;
}

function toDelimited(number) {
  var match, property, integerPart, fractionalPart;
  var settings = {
    precision: 2,
    unit: i18nunit,
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };

  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

function toCurrency(number) {
  
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 2,
    unit: i18nunit,
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };
  if (!typeof number == 'number') {
    number = toFloat(number);
  }
  if (typeof number == 'undefined') {
    number = 0;
  }
  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return settings.unit + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

function toPercent(number) {
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 0,
    unit: "%",
    separator: i18nseparator,
    delimiter : i18ndelimiter
  };

  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return '' + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "") + settings.unit;
}
