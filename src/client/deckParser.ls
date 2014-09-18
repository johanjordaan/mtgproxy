_ = require 'prelude-ls'

deckParser = {}
if module?
  module.exports = deckParser


getLines = (deckText) ->
  # Replace all \r with empty strings and split on \n
  #
  deckText = deckText.replace /\r?/g, ''
  lines = deckText.split '\n'

  # Replace all whitespace characters with a single space character
  #
  lines = lines |> _.map (item) -> item.replace /\s/g,' '


  # Convert comment types to unified comment type
  #
  lines  = lines |> _.map (item) -> item.replace '#','//'
  lines  = lines |> _.map (item) -> item.replace ';','//'

  # Trim all leading and training empty spaces
  #
  lines  = lines |> _.map (item) -> item.trim()

  # Remove the word sideboard sothat mtgo decks are readable
  #
  lines  = lines |> _.map (item) -> item.replace 'Sideboard',''


  # Remove all lines starting with comment //
  #
  lines = lines |> _.filter (item) ->
    switch item.indexOf '//'
    | 0 => false
    | otherwise => true

  # Remove all inline comments
  #
  lines  = lines |> _.map (item) ->
    idx = item.indexOf '//'
    switch idx > 0
    | true => item.slice(0,idx).trim()
    | otherwise => item

deckParser.parse = (deckText) ->
  cards = []
  errors = []

  if deckText.trim().length == 0
    errors.push { type:'warning', lineNo:0, line:deckText, message:'empty input' }

  lines = getLines deckText

  firstEmptyLine = -1
  emptyLineSBDelimiter = true
  for line,idx in lines
    originalLine = line

    switch line.length
    | 0 =>
      # Track where the first empty line is. This will indicate the start
      # of the sideboard
      #
      switch firstEmptyLine
      | -1 => firstEmptyLine = idx
      | otherwise =>
    | otherwise =>

      sb = false
      if line.indexOf('SB') == 0
        sb = true
        line = line.replace('SB','').replace(':','').trim()
        emptyLineSBDelimiter = false

      tokens = line.split(/[ |x|X](.+)/) |> _.map (item) ->
        item
        .replace(/\[(.*)]/,'')    # Remove the [ed] component
        .trim()

      newCard = do
        count: Number(tokens[0])
        name: tokens[1]
        sb: sb

      # Do some validations
      #
      hasError = false
      if !newCard.name?
        errors.push { type:'error', lineNo:idx, line:originalLine, message:'invalid line' }
        hasError = true
      if newCard.count <= 0
        errors.push { type:'error', lineNo:idx, line:originalLine, message:'invalid line' }
        hasError = true
      if _.isItNaN newCard.count
        errors.push { type:'error', lineNo:idx, line:originalLine, message:'invalid line' }
        hasError = true


      # Do some more validations
      #


      if !hasError
        cards.push  newCard


  # Post process the list to mark the SB cards if we used the empty line
  # method of delimiing SB from maindeck
  #
  if emptyLineSBDelimiter
    for card,idx in cards
      if firstEmptyLine != -1 and idx >= firstEmptyLine
        card.sb = true

  return
    cards: cards
    errors: errors


ngDeckParser = {}
if angular?
  ngDeckParser := angular.module 'ngDeckParser',[]
  ngDeckParser.constant 'DeckParser', deckParser
