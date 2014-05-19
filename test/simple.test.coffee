should = require 'should'
express = require 'express'
request = require 'request'

mailer = require '../lib'

mailer.configure
  sender: "Tarkus <hello@tarkus.im>"
  view_path: "#{__dirname}"

describe 'Express Sendmail', ->

  before (done) ->
    app = express()

    app.get '/', (req, res, next) ->
      variables =
        username: "John"
        content: "How are you?"
      mailer.send 'test',
        subject: "Long time no see"
        to: "hello@tarkus.im"
      , variables, (error, response) ->
        res.send response
    app.listen 23456

    done()

  it 'should render mail template', (done) ->
    request "http://localhost:23456", (error, response, body) ->
      body.should.match /Hello, John/
      done()
