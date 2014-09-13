_  = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

mainController = ($scope,$timeout,DeckParser,Api) ->
  $scope.deck = '''
  1 Duress
  1 Raging Goblin
  1 Wrath of God

  1 Duress
  '''

  $scope.link = ""
  $scope.requestCount = '...'
  $scope.hasLink = false
  $scope.isGenerating = false
  $scope.skipBasicLands = true

  poll = ->
    Api.getRequestCount (data) ->
      $scope.requestCount = data.requestCount
      $timeout ->
        poll
      ,3000
  poll!

  $scope.$watch 'skipBasicLands', (oldVal,newVal) ->
    localStorage["mtgproxy.skipBasicLands"] = $scope.skipBasicLands

  $scope.$watch 'deck', (oldVal,newVal) ->
    localStorage["mtgproxy.deck"] = $scope.deck

  if localStorage["mtgproxy.skipBasicLands"]?
    $scope.skipBasicLands = localStorage["mtgproxy.skipBasicLands"]
  if localStorage["mtgproxy.deck"]?
    $scope.deck = localStorage["mtgproxy.deck"]


  $scope.generate = ->
    $scope.isGenerating = true
    $scope.hasLink = false

    result = DeckParser.parse $scope.deck

    Api.generate { cards: result.cards , skipBasicLands: $scope.skipBasicLands }, (data)->
      $scope.link = "/docs/#{data.documentUrl}"
      Api.getRequestCount (data) ->
        $scope.requestCount = data.requestCount
      $timeout ->
        $scope.isGenerating = false
        $scope.hasLink = true
      , 1000

apiFactory = ($resource,ErrorHandler) ->
  do
    getRequestCount: (cb) ->
      $resource '/api/v1/stats', null
      .get {}, {}, cb, ErrorHandler

    generate: (data, cb) ->
      $resource '/api/v1/generate', null
      .save {}, data, cb, ErrorHandler

errorHandlerFactory = (Errors) ->
  (err) ->
    Errors.push err.data.message

config = ($routeProvider) ->
  $routeProvider
  .when '/home', do
    templateUrl: 'main.html'
    controller: 'mainController'

  .otherwise do
    redirectTo: '/home'


app = angular.module 'gameApp',['ngResource','ngRoute','ngDeckParser']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.value 'Errors',[]

app.controller 'errorController', ['$scope','Errors',errorController]

app.controller 'mainController', ['$scope','$timeout','DeckParser','Api',mainController]

app.config ['$routeProvider',config]
