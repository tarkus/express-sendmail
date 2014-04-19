fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
mailer = require 'nodemailer'
_      = require 'underscore'

config = {}
templates = {}
filenames = {}
transport = null

send_function = (req, res, next) ->
  (mail, options, variables, callback) ->
    defaults = from: config.sender or "<noreply@example.com>"

    if typeof variables is 'function'
      callback = variables
      variables = {}

    options = _.extend options, defaults

    return callback "No Recipient" unless options.to?
    return callback "No Such Mail" unless templates["#{mail}.txt"]?

    unless options.subject
      if res.locals.t
        options.subject = res.locals.t("mailer.#{mail}.subject")

    return transport.sendMail options, callback if options.text or options.html

    variables.t = res.locals.t
    variables.filename = filenames["#{mail}.txt"]

    jade.render templates["#{mail}.txt"], variables, (err, text) ->
      return callback err if err
      options.text = text
      return transport.sendMail options, callback unless templates["#{mail}.html"]

      variables.filename = filenames["#{mail}.html"]
      jade.render templates["#{mail}.html"], variables, (err, html) ->
        return callback err if err
        options.html = html
        return transport.sendMail options, callback

exports.connect = (_config) ->

  ###
    smtp:
      service: "Mandrill"
      auth:
        user: "tarkus"
        pass: "password"
    sender: "Tarkus <hello@tarkus.im>"
    view_path: "views/mailer"
  ###

  config = _.extend config, _config
  throw new Error "view_path must be set" unless config.view_path

  files = fs.readdirSync config.view_path

  if files
    for file in files
      fullpath = path.join config.view_path, file
      templates[path.basename(file, '.jade')] = fs.readFileSync(fullpath).toString()
      filenames[path.basename(file, '.jade')] = fullpath

  if config.smtp
    transport = mailer.createTransport 'SMTP', config.smtp
  else
    transport = mailer.createTransport 'Stub'

  (req, res, next) ->
    res.sendmail = send_function req, res, next
    next()



  

    





