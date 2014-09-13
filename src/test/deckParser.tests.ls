_ = require 'prelude-ls'
assert = require('assert')
should = require('chai').should()
expect = require('chai').expect

deckParser = require '../client/deckParser'

describe 'deckParser', (done) ->
  describe 'parse deck with newline delimiter', (done) ->
    it 'should parse deck with newline delimiting the SB deck into JSON', (done) ->
      deck = '''
      // This is my sample deck
      1xWrath of God     # My awsome card ....
      10x  Plains         ; Silly land
      1 Raging Goblin   // What an awesome card

      2  [7E]   Counterspell
      '''

      result = deckParser.parse deck

      result.errors.length.should.equal 0
      result.cards.length.should.equal 4
      mainDeck = result.cards |> _.filter (item) -> !item.sb
      sideBoard = result.cards |> _.filter (item) -> item.sb

      mainDeck.length.should.equal 3
      sideBoard.length.should.equal 1


      done!

  describe 'parse deck with SB delimiter', (done) ->
    it 'should parse deck with newline delimiting the SB deck into JSON', (done) ->
      deck = '''
      // This is my sample deck
      1xWrath of God     # My awsome card ....
      10x  Plains         ; Silly land
      1 Raging Goblin   // What an awesome card

      SB :2x Duress
      SB:2xFireball
      '''

      result = deckParser.parse deck

      result.errors.length.should.equal 0
      result.cards.length.should.equal 5
      mainDeck = result.cards |> _.filter (item) -> !item.sb
      sideBoard = result.cards |> _.filter (item) -> item.sb

      mainDeck.length.should.equal 3
      sideBoard.length.should.equal 2


      done!


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
