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

# console.log 'Model', model

router.route '/contact'
  .post (req, res) ->
    contact req, (result) ->
      res.json result: result

validated =
  comment: (comment) ->
    return false unless typeof comment is 'object'
    # console.log 'validating', comment
    return true if comment.postId and comment.author and comment.text
    false

strip-tags = (text) ->
  text.replace /(<([^>]+)>)/ig ,""

# http://www.componentix.com/blog/9/file-uploads-using-nodejs-now-for-real
# Multipart form data
# https://github.com/expressjs/multer
# https://www.npmjs.com/package/multiparty#readme
router.route '/comment/new'
  .post (req, res) ->
    data = req.body
    # console.log 'data', data
    try
      if data
        comment = if typeof data is 'string' then JSON.parse(data) else data
        # console.log 'parsed comment', comment
        if validated.comment comment
          # console.log 'valid comment', comment

#          model.comment.remove postId: 16, (err) ->
#            if err
#              console.error 'error', err
#            else
#              console.log 'all comments with postId 16 removed'

          # markdown = require "markdown" .markdown
          # comment.text = markdown.toHTML comment.text
          comment.text = strip-tags comment.text
          comment.author = strip-tags comment.author

          newComment = new model.comment postId: comment.postId, author: comment.author, text: comment.text
          # console.log 'new comment', newComment
          newComment.save (err) ->
            # console.log 'saved comment'
            if err
              console.log 'error', err
              res.send ''
            else
              # console.log 'send comment back'
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
  # console.log 'SHOW POST', post.title, post.id

  if post
    query = postId: post.id
    # console.log 'find all comments for', post.id
    model.comment.find().exec (err, result) ->
      # console.log err, result
      comments = if err then [] else result
      # console.log 'comments', comments
      res.render 'post', post: post, comments: comments
  else
    res.send 404

module.exports = app
