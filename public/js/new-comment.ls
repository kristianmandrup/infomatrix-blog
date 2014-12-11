lastComment = null

scrollTo = (target, speed, cb) ->
    if typeof(speed) == 'undefined'
        speed = 1000

    top = parseInt $(target).offset().top - 200

    $('html, body').animate scrollTop: top, speed, cb

htmlEncode = (value) ->
  $('<span />').html value

textElement = (comment) ->
  # text = convertToLinks(comment.text)
  $("<div class='text' />").append htmlEncode(comment.text)

authorElement = (comment) ->
  $("<div class='author'/>").text(comment.author)


success = (newComment) ->
  if JSON.stringify(newComment) === lastComment
    return false

  lastComment := JSON.stringify(newComment)

  document.querySelector('form#new-comment').reset!

  if typeof newComment is 'object'
    newCommentElement = $("<div></div>")
    newCommentElement.addClass('comment').addClass('new')
    newCommentElement
    .append textElement(newComment)
    .append authorElement(newComment)

    $('#comments').prepend newCommentElement

    newCommentElement.fadeOut 5

    # scrollTo newCommentElement, 1000, ->
    newCommentElement.fadeIn 2500, ->
      newCommentElement.removeClass 'new'

formSelector = '#new-comment'

extract-data = ->
  author  = $('#comment-author').val!
  text    = $('#comment-text').val!
  postId  = $('#postId').val!
  return
    author: author
    text: text
    postId: postId


$('button#comment-submit').click (e) ->
  e.preventDefault!
  form = $(formSelector)
  unless form
    throw Error "form not found: #{formSelector}"

  data = extract-data!

  ajaxOptions =
    dataType: 'json'
    data: data
    method: 'POST'
    url: '/comment/new'
    success: success

  $.ajax(ajaxOptions).done(success).fail ->
    console.log 'ajax post failed'

