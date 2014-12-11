express = require 'express'
app = express!
Poet = require 'poet'

# multipart = require "multipart"

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
app.use express.static(__dirname + '/public')

app.get '/rss', (req, res) ->
  # Only get the latest posts
  posts = poet.helpers.getPosts 0, 5
  res.setHeader 'Content-Type', 'application/rss+xml'
  res.render 'rss', posts: posts

contact = require './mail/contact'

body-parser = require 'body-parser'
app.use bodyParser.json! # to support JSON-encoded bodies
app.use bodyParser.urlencoded extended: true

# app.use express.json!       # to support JSON-encoded bodies
# app.use express.urlencoded!  # to support URL-encoded bodies
model = require './data/model'

router = express.Router()

poet = Poet app,
  meta-format: 'yaml'
  posts-per-page: 5

poet.init!.then( ->
  console.log 'poet initialized'
  console.log Object.keys(poet.posts)
  done!
)

remove-comments = (conditions) ->
  model.comment.remove conditions, (err) ->
    if err
      console.error 'error', err
    else
      console.log 'all comments with #{conditions} removed'

router.route '/contact'
  .post (req, res) ->
    contact req, (result) ->
      res.json result: result

validated =
  comment: (comment) ->
    return false unless typeof comment is 'object'
    return true if comment.postId and comment.author and comment.text
    false

strip-tags = (text) ->
  text.replace /(<([^>]+)>)/ig ,""

# convert-to-links = require './public/js/convert-to-links'
marked = require 'marked'

#marked.setOptions
#  renderer: new marked.Renderer()
#  gfm: true
#  tables: true
#  breaks: false
#  pedantic: false
#  sanitize: true
#  smartLists: true
#  smartypants: false

router.route '/comment/new'
  .post (req, res) ->
    data = req.body
    # console.log 'data', data
    try
      if data
        comment = if typeof data is 'string' then JSON.parse(data) else data
        if validated.comment comment

          comment.text = marked(comment.text)
          # comment.text = convert-to-links text

          comment.author = strip-tags comment.author

          newComment = new model.comment postId: comment.postId, author: comment.author, text: comment.text
          newComment.save (err) ->
            if err
              console.log 'error', err
              res.send ''
            else
              res.send comment
          return
        else
          console.log 'invalid comment', comment
    catch e
      console.error 'error', e
      res.send ''


app.use '/', router

poet.addRoute '/posts', (req, res) ->
  page = 1
  lastPost = page * 3;
  res.render 'page',
    posts: poet.helpers.getPosts lastPost - 3, lastPost
    page: page

poet.addRoute '/post/:post', (req, res) ->
  model.comment.remove postId: 16

  post = poet.helpers.getPost req.params.post

  if post
    query = postId: post.id
    model.comment.find().sort({date: 'desc'}).exec (err, result) ->
      comments = if err then [] else result
      res.render 'post', post: post, comments: comments
  else
    res.send 404

module.exports = app
