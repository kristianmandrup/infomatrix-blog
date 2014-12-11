mongoose = require "mongoose"

# Here we find an appropriate database to connect to, defaulting to
# localhost if we don't find one.
uristring = process.env.MONGOLAB_URI or process.env.MONGOHQ_URL or 'mongodb://localhost/Infomatrix'

# Makes connection asynchronously.  Mongoose will queue up database
# operations and release them when the connection is complete.
mongoose.connect uristring, (err, res) ->
  if err
    console.log 'ERROR connecting to: ' + uristring + '. ' + err
  else
    console.log 'Succeeded connected to: ' + uristring

schema = {}

# This is the schema.  Note the types, validation and trim
# statements.  They enforce useful constraints on the data.
schema.comment = new mongoose.Schema(
  postId:
    type: Number
    min: 0
  author: String
  text:
    type: String
    trim: true
  date:
    type: Date
    default: Date.now
)

model = {}

model.comment = mongoose.model 'Comment', schema.comment

# console.log 'exports', model

module.exports = model