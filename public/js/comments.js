// Generated by LiveScript 1.2.0
(function(){
  $().ready(function(){
    return $('.comment-date').each(function(index, dateElem){
      var elem, text, fromNow;
      elem = $(dateElem);
      text = elem.text();
      fromNow = moment(text).fromNow();
      return elem.html(fromNow);
    });
  });
}).call(this);
