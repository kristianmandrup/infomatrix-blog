lastComment = null

scrollTo = (target, speed, cb) ->
    if typeof(speed) == 'undefined'
        speed = 1000

    top = parseInt $(target).offset().top - 200
    # console.log 'top', top

    $('html, body').animate scrollTop: top, speed, cb

success = (newComment) ->
  # console.log 'newComment', newComment, 'vs', lastComment
  if JSON.stringify(newComment) === lastComment
    return false

  lastComment := JSON.stringify(newComment)

  # console.log 'Comment posted', newComment
  document.querySelector('form#new-comment').reset()

  if typeof newComment is 'object'
    newCommentElement = $("<div></div>")
    newCommentElement.addClass('comment').addClass('new')
    newCommentElement.append "<div class='text'>" + newComment.text + "</div>" +
      "<div class='author'>" + newComment.author + "</div>"

    $('#comments').append newCommentElement

    newCommentElement.fadeOut 5
    # console.log 'scroll to new comment', newCommentElement

    scrollTo newCommentElement, 1000, ->
      # console.log 'animate complete'
      newCommentElement.fadeIn 2500, ->
        # console.log 'fadeIn complete'
        newCommentElement.removeClass 'new'

# commentForm.ajaxForm success

formSelector = '#new-comment'

$('button#comment-submit').click (e) ->
  e.preventDefault!
  console.log 'ajax submit'
  form = $(formSelector)
  unless form
    throw Error "form not found: #{formSelector}"

#  console.log 'form', form
#  if typeof form.serializeJSON is 'function'
#    data = form.serializeJSON!
#    console.log "serialized to json"
#  else
#    console.error "serializeJSON not available on form: #{form.serializeJSON}"
#    data = form.serialize!
#    console.log 'serialized', data

  # unless data
  author = $('#comment-author').val!
  text = $('#comment-text').val!
  postId = $('#postId').val!
  data =
    author: author
    text: text
    postId: postId

  # console.log 'data', data

  ajaxOptions =
    dataType: 'json'
    data: data
    method: 'POST'
    url: '/comment/new'
    success: success

  # console.log 'ajax options', ajaxOptions

  $.ajax(ajaxOptions).done(success).fail ->
    console.log 'ajax post failed'

