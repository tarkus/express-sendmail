fs     = require 'fs'
path   = require 'path'
jade   = require 'jade'
mailer = require 'nodemailer'
_      = require 'underscore'

settings  = {}
templates = {}
filenames = {}
transport = null

exports.send = (mail, options, variables, done) ->
    defaults = from: options.sender or settings.sender

    if typeof variables is 'function'
      done = variables
      variables = {}

    options = _.extend options, defaults

    return callback "No Recipient" unless options.to?
    return callback "No Such Mail" unless templates["#{mail}.txt"]?

    unless options.subject
      if variables.t
        options.subject = variables.t("mailer.#{mail}.subject")

    return transport.sendMail options, callback if options.text or options.html

    text_mail = (callback) ->
      return callback() unless filenames["#{mail}.txt"]
      variables.filename = filenames["#{mail}.txt"]
      jade.render templates["#{mail}.txt"], variables, (err, text) ->
        return callback err if err
        options.text = text
        return callback()

    html_mail = (callback) ->
      return callback() unless filenames["#{mail}.html"]
      variables.filename = filenames["#{mail}.html"]
      jade.render templates["#{mail}.html"], variables, (err, html) ->
        return callback err if err
        options.html = html
        return callback()

    text_mail -> html_mail -> transport.sendMail options, done

exports.configure = (_options) ->

  ###
    smtp:
      service: "Mandrill"
      auth:
        user: "tarkus"
        pass: "password"
    sender: "Tarkus <hello@tarkus.im>"
    view_path: "views/mailer"
  ###

  options = _.extend settings, _options
  throw new Error "view_path must be set" unless settings.view_path

  files = fs.readdirSync settings.view_path

  if files
    for file in files
      fullpath = path.join options.view_path, file
      templates[path.basename(file, '.jade')] = fs.readFileSync(fullpath).toString()
      filenames[path.basename(file, '.jade')] = fullpath

  if settings.smtp
    transport = mailer.createTransport 'SMTP', settings.smtp
  else
    transport = mailer.createTransport 'Stub'
