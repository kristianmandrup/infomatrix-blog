$().ready ->
  $('.comment-date').each (index, dateElem) ->
    elem = $(dateElem)
    text = elem.text!
    fromNow = moment(text).fromNow!
    elem.html fromNow
