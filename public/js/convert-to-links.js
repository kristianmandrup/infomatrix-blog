function convertToLinks(text) {
  var replaceText, replacePattern1;

  //URLs starting with http://, https://
  replacePattern1 = /(\b(https?):\/\/[-A-Z0-9+&amp;@#\/%?=~_|!:,.;]*[-A-Z0-9+&amp;@#\/%=~_|])/ig;
  replacedText = text.replace(replacePattern1, '<a class="link" title="$1" href="$1" target="_blank">$1</a>');

  //URLs starting with "www."
  replacePattern2 = /(^|[^\/])(www\.[\S]+(\b|$))/gim;
  replacedText = replacedText.replace(replacePattern2, '$1<a class="link" href="http://$2" target="_blank">$2</a>');

  //returns the text result
  return replacedText;
}

if (module === undefined) {
  var module = {}
}

module.exports = convertToLinks
