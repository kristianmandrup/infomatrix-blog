express = require 'express'
app = express!
Poet = require 'poet'

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
app.use bodyParser.urlencoded(extended: true)

# app.use express.json!       # to support JSON-encoded bodies
# app.use express.urlencoded!  # to support URL-encoded bodies

app.post '/contact', (req, res) ->
  console.log 'Request', req.body
  contact req, (result) ->
    res.json result: result

poet = Poet app,
  meta-format: 'yaml'
  posts-per-page: 5

poet.addRoute '/posts', (req, res) ->
  page = 1
  lastPost = page * 3;
  res.render 'page',
    posts: poet.helpers.getPosts lastPost - 3, lastPost
    page: page

poet.init!.then( ->
  console.log 'poet initialized'
  console.log Object.keys(poet.posts)
  done!
)

module.exports = app