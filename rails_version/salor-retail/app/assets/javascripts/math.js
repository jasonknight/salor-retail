sr.fn.math.round = function(Number, DecimalPlaces) {
 return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
}

sr.fn.math.roundFixed = function(Number, DecimalPlaces) {
 return sr.fn.math.round(Number, DecimalPlaces).toFixed(DecimalPlaces);
}

sr.fn.math.toFloat = function(str, returnString) {
  str = str.replace(Region.number.currency.format.delimiter, '');
  str = str.replace(Region.number.currency.format.separator, '.');
  return parseFloat(str);
}

sr.fn.math.roundNumber = function(num, dec) {
  var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
  return result;
}

sr.fn.math.toDelimited = function(number, precision) {
  if (typeof number == 'undefined') {
    sr.fn.debug.echo("warning in toDelimited");
    return "";
  }
  
  if (typeof precision == 'undefined') {
    precision = 2;
  }
    
  var match, property, integerPart, fractionalPart;
  var settings = {
    precision: precision,
    unit: Region.number.currency.format.unit,
    separator: Region.number.currency.format.separator,
    delimiter : Region.number.currency.format.delimiter
  };
  if (typeof number == 'undefined' || number == null) {
    number = 0.0;
  }
  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

sr.fn.math.toCurrency = function(number) {
  if (typeof number == 'undefined') {
    sr.fn.debug.echo("toCurrency: number is type undefined");
    return "";
  }
  
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 2,
    unit: Region.number.currency.format.unit,
    separator: Region.number.currency.format.separator,
    delimiter : Region.number.currency.format.delimiter
  };
  if (!typeof number == 'number') {
    number = sr.fn.math.toFloat(number);
  }
  if (typeof number == 'undefined' || number == null) {
    number = 0.0;
  }
  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);
  return settings.unit + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "");
}

sr.fn.math.toPercent = function(number) {
  if (typeof number == 'undefined') {
    sr.fn.debug.echo("warning in toPercent");
    return "";
  }
  var match, property, integerPart, fractionalPart;
  var settings = { 
    precision: 1,
    unit: "%",
    separator: Region.number.currency.format.separator,
    delimiter : Region.number.currency.format.delimiter
  };
  if (typeof number == 'undefined' || number == null) {
    number = 0.0;
  }
  match = number.toString().match(/([\+\-]?[0-9]*)(.[0-9]+)?/);

  if (!match) return;

  integerPart = match[1].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1" + settings.delimiter);
  fractionalPart = match[2] ? (match[2].toString() + "000000000000").substr(1, settings.precision) : "000000000000".substr(1, settings.precision);

  return '' + integerPart + ( settings.precision > 0 ? settings.separator + fractionalPart : "") + settings.unit;
}
