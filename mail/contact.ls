nodemailer  = require 'nodemailer'
fs          = require 'fs'
config-file = 'config/mail-config.json'

try
  # file-json = require config-file
  file-json = fs.readFileSync config-file
catch err
  console.error err

mail-config = JSON.parse file-json

console.log 'using mail-config:', mail-config

# create reusable transporter object using SMTP transport
smtpTransport = nodemailer.createTransport mail-config

smtpTransport.on 'log', console.log

options =
  me: 'kmandrup@gmail.com'

# Mail options
mail = (body) ->
  from: body.name + ' <' + body.email + '>'
  to: options.me,
  subject: body.subject || 'Infomatrix Contact'
  text: body.message

msg-for = (err) ->
  if err then 'Error occured, message not sent.' else 'Message sent! Thank you.'

# NB! No need to recreate the transporter object. You can use
# the same transporter object for all e-mails
send-email = (req, callback) ->
  console.log 'send email Request:', req
  console.log 'Body:', req.body
  # send mail with defined transport object
  options = mail req.body

  console.log 'with options', options
  smtpTransport.send-mail options, (error, info) ->
    err = !!error
    console.log 'mail result', err, info
    callback err


module.exports = send-email