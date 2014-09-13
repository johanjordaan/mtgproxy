_ = require 'prelude-ls'

deckParser = {}
module.exports = deckParser


getLines = (deckText) ->
  # Replace all \r with empty strings and split on \n
  #
  deckText = deckText.replace /\r?/g, ''
  lines = deckText.split '\n'

  # Convert comment types to unified comment type
  #
  lines  = lines |> _.map (item) -> item.replace '#','//'
  lines  = lines |> _.map (item) -> item.replace ';','//'

  # Trim all leading and training empty spaces
  #
  lines  = lines |> _.map (item) -> item.trim()

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
  lines = getLines deckText

  allCards = []

  firstEmptyLine = -1
  emptyLineSBDelimiter = true
  for line,idx in lines
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

      allCards.push do
        count: Number(tokens[0])
        cardName: tokens[1]
        sb: sb

  # Post process the list to mark the SB cards if we used the empty line
  # method of delimiing SB from maindeck
  #
  if emptyLineSBDelimiter
    for card,idx in allCards
      if idx >= firstEmptyLine
        card.sb = true

  allCards
