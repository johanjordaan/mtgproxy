fs = require 'fs'
async = require 'async'
_ = require 'prelude-ls'
PDFDocument = require 'pdfkit'
moment = require 'moment'


express = require 'express'
bodyParser = require 'body-parser'

#utils = require './utils'
#lcg = require 'lcg-rnd'

app = express()

# Configure express
app.use bodyParser.json()
app.use '/',express.static(__dirname + '/client')
app.use '/docs',express.static(__dirname + '/docs')


server = (require 'http').createServer app

LISTEN_PORT = 4000

######## DB Initialisation
mongo = require 'mongoskin'
ObjectID = require('mongoskin').ObjectID
db_name = "mongodb://localhost/mtgproxy"
db = mongo.db db_name, {native_parser:true}
db.bind 'cards'
db.bind 'requests'



/* istanbul ignore if */
if require.main == module
  server.listen LISTEN_PORT, ->
     console.log "mqz API Server - Listening on port #{LISTEN_PORT}"
else
  module.exports = (test_db) ->
    /* istanbul ignore else */
    if test_db?
      db := test_db
      db.bind 'cards'
    app

# Setup the file cleanup
cleanupFiles = ->
  docPath = "./dist/docs/"
  fs.readdir docPath, (err,files) ->
    | err? => console.log err
    | otherwise =>
      for file in files
        x = (file) ->
          fs.stat "#{docPath}#{file}", (err,stat) ->
            age = moment().diff(stat.ctime, 'minutes')
            switch age<15
            | true =>
            | otherwise =>
              fs.unlink "#{docPath}#{file}", (err) ->
                | err? => console.log err
                | otherwise =>

        x file

  setTimeout -> cleanupFiles()
  ,30000


cleanupFiles!

drawBorders = (doc,offset,w,h) ->
  doc.save()
    .moveTo(offset, offset)
    .lineTo(offset, h)
    .lineTo(w, h)
    .lineTo(w, offset)
    .lineTo(offset, offset)
    .stroke()

  doc.save()
    .moveTo(w/3 *1, offset)
    .lineTo(w/3 *1, h)
    .moveTo(w/3 *2, offset)
    .lineTo(w/3 *2, h)
    .moveTo(w/3 *3, offset)
    .lineTo(w/3 *3, h)
    .stroke()

  doc.save()
    .moveTo(offset, h/3 *1)
    .lineTo(w, h/3 *1)
    .moveTo(offset, h/3 *2)
    .lineTo(w, h/3 *2)
    .moveTo(offset, h/3 *3)
    .lineTo(w, h/3 *3)
    .stroke()

createDoc = (name,cards) ->

  # Create a document
  doc = new PDFDocument("A4")

  # Pipe it's output somewhere, like to a file or HTTP response
  # See below for browser usage
  doc.pipe fs.createWriteStream(name)

  #8.267 in × 11.692 in
  offset = 0
  padding = 5
  scale = 0.90
  w = 8.267*72*scale
  h = 11.692*72*scale

  x = 0
  y = 0
  drawBorders doc,offset,w,h
  cnt = 0
  for card in cards
    cnt = cnt+1
    if card.name not in ["Island","Swamp","Plains","Forest","Mountain"]
      doc.fontSize 8
      doc.text card.manaCost,(w/3)*x,offset+((h/3)*y)+padding,{ width: w/3 -padding, align: 'right'}
      doc.fontSize 10
      doc.text card.name,offset+((w/3)*x)+padding,offset+((h/3)*y)+padding,{ width: w/3 , align: 'left'}
      doc.fontSize 8
      doc.text card.type,offset+((w/3)*x)+padding,offset+((h/3)*y)+padding+40,{ width: w/3 , align: 'justify'}
      doc.fontSize 8
      doc.text card.text,offset+((w/3)*x)+padding,offset+((h/3)*y)+padding+70,{ width: w/3 -(padding*2), align: 'left'}

      if card.pt?
        doc.fontSize 12
        doc.text card.pt,(w/3)*x,offset+((h/3)*y)+padding+(190),{ width: w/3 -padding, align: 'right'}

      x = x+1
      if x%3 == 0
        x = 0
        y = y+1

      if y!=0 and y%3 == 0
        x=0
        y=0
        if cnt<cards.length
          doc.addPage!
          drawBorders doc,offset,w,h



  # Finalize PDF file
  doc.end()

loadCards = (list,cb) ->
  tasks = []
  for item in list
    x = (item) ->
      tasks.push (cb) ->
        db.cards.findOne { name: item },  (err, dbCard) ->
          | !dbCard? =>
            console.log "[#{item}] - Not Found"
            cb null,{name:"#{item} - not found"}
          | otherwise => cb null,dbCard
    x item

  # use sries otherwise the mongoskin adds to manu concurrent listeners
  # plus series vs parallel is not an issue here
  async.series tasks, (err,results) ->
    cb results


loadDeck = (data, cb) ->
  mainDeckList = []
  sideBoardList = []

  data = JSON.parse(data)
  data = data.replace(/\r?/g, '')
  lines = data.split('\n')
  main = true
  for line in lines
    tokens = line.split(/[ ](.+)/)
    if tokens.length<2
      main = false
    else
      switch main
      | true =>
        for i to Number(tokens[0])-1
          mainDeckList.push tokens[1]
      | otherwise =>
        for i to Number(tokens[0])-1
          sideBoardList.push tokens[1]

  loadCards mainDeckList, (mainDeck) ->
    loadCards sideBoardList, (sideBoard) ->
      cb mainDeck, sideBoard


app.post '/api/v1/generate/', (req, res) ->
  cardList = req.body.cardList
  db.requests.save {cardList:cardList}, (err, savedRequest) ->
    | err? => res.status(500).send err
    | otherwise =>
      loadDeck cardList, (mainDeck,sideBoard) ->
        createDoc "./dist/docs/#{savedRequest._id}.pdf" ,mainDeck
        res.status(200).send { documentUrl:"#{savedRequest._id}.pdf" }



app.get '/api/v1/requestcount/', (req, res) ->
  db.requests.count {}, (err,count) ->
    | err? => res.status(500).send err
    | otherwise => res.status(200).send { count: count }
