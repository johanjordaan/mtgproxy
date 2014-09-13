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

      cards = deckParser.parse deck

      cards.length.should.equal 4
      mainDeck = cards |> _.filter (item) -> !item.sb
      sideBoard = cards |> _.filter (item) -> item.sb

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

      cards = deckParser.parse deck

      cards.length.should.equal 5
      mainDeck = cards |> _.filter (item) -> !item.sb
      sideBoard = cards |> _.filter (item) -> item.sb

      mainDeck.length.should.equal 3
      sideBoard.length.should.equal 2


      done!
