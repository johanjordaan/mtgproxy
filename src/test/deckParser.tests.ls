_ = require 'prelude-ls'
fs = require 'fs'
assert = require('assert')
should = require('chai').should()
expect = require('chai').expect

deckParser = require '../client/deckParser'


decks = [
  { name:"various_formats_no_sb", crdlines:4, mdl:13, sbl:0 }
  { name:"various_formats_nl_sb", crdlines:5, mdl:13, sbl:2 }
  { name:"various_formats_sb_sb", crdlines:6, mdl:13, sbl:4 }
  { name:"mtgo_deck", crdlines:25, mdl:60, sbl:15  }
]

testDeck = (spec,done) ->
  it "should parse [#{spec.name}]", (done) ->
    fs.readFile "./src/test/test_decks/#{spec.name}.txt",'utf8',(err,data) ->
      result = deckParser.parse data
      result.errors.length.should.equal 0
      result.cards.length.should.equal spec.crdlines
      mainDeck = result.cards |> _.filter (item) -> !item.sb
      sideBoard = result.cards |> _.filter (item) -> item.sb

      mainDeckCount = _.fold (a,b) ->
        a + b.count
      ,0
      ,mainDeck

      sideBoardCount = _.fold (a,b) ->
        a + b.count
      ,0
      ,sideBoard

      mainDeckCount.should.equal spec.mdl
      sideBoardCount.should.equal spec.sbl

      done!



describe 'deckParser', (done) ->
  describe 'it should parse all the sample decks', (done) ->
    for deck in decks
      testDeck deck,done

  describe 'pasing invalid decks', (done) ->
    it 'should fail nicely', (done) ->
      result = deckParser.parse ''
      result.cards.length.should.equal 0
      result.errors.length.should.equal 1
      done!

    it 'should fail nicely', (done) ->
      result = deckParser.parse 'x wwww w w w'
      result.cards.length.should.equal 0
      result.errors.length.should.equal 1
      done!

    it 'should fail nicely', (done) ->
      result = deckParser.parse '100'
      result.cards.length.should.equal 0
      result.errors.length.should.equal 1
      done!

    it 'should fail nicely', (done) ->
      result = deckParser.parse 'SSS: 100 Wrath of God'
      result.cards.length.should.equal 0
      result.errors.length.should.equal 1
      done!
