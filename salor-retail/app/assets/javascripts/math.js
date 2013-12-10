function Round(Number, DecimalPlaces) {
 return Math.round(parseFloat(Number) * Math.pow(10, DecimalPlaces)) / Math.pow(10, DecimalPlaces);
}

function RoundFixed(Number, DecimalPlaces) {
 return Round(Number, DecimalPlaces).toFixed(DecimalPlaces);
}

function toFloat(str, returnString) {
  str = str.replace(Region.number.currency.format.delimiter, '');
  str = str.replace(Region.number.currency.format.separator, '.');
  return parseFloat(str);
}

function roundNumber(num, dec) {
  var result = Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
  return result;
}

function toDelimited(number) {
  if (typeof number == 'undefined') {
    sr.fn.debug.echo("warning in toDelimited");
    return "";
  }
  
  var match, property, integerPart, fractionalPart;
  var settings = {
    precision: 2,
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

function toCurrency(number) {
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
    number = toFloat(number);
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

function toPercent(number) {
  if (typeof number == 'undefined') {
    sr.fn.debug.echo("warning in toPercent");
    return "";
  }
  var match, property, integerPart, fractionalPart;
  var settings = {         precision: 0,
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
