_ = require 'prelude-ls'
fs = require 'fs'
mongo = require 'mongoskin'
async = require 'async'

ObjectID = require('mongoskin').ObjectID
db_name = "mongodb://localhost/mtgproxy"
db = mongo.db db_name, {native_parser:true}
db.bind 'cards'


importAllCards = (fileName) ->
  db.cards.remove { },(err,writeResult) ->
    | err? => console.log err
    | otherwise =>
      fs.readFile fileName, 'utf8', (err, data) ->
        | err? => console.log err
        | otherwise =>
          cards = JSON.parse(data)
          inserts = []
          for cardName in _.keys cards
            console.log
            card = cards[cardName]
            x = (card) ->
              inserts.push (cb) ->
                # Customisations
                if card.power? then card.pt = "#{card.power}/#{card.toughness}"
                if card.colors? then card.color = _.join " ",card.colors
                console.log "Saving #{card.name} ... "
                db.cards.save card,(err) ->
                  | err? =>
                     console.log err
                     cb(null,err)
                  | otherwise => cb(null,true)
            x card
            console.log "#{cardName}, #{inserts.length}"
          async.parallel inserts, (err,results) ->
            console.log "... #{err}"
            if results?
               console.log results.length
            if inserts?
               console.log inserts.length
            db.close!

importAllCards './AllCards.json'
