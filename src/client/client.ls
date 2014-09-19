_  = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

mainController = ($scope,$interval,$timeout,Errors,DeckParser,Api) ->
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

  pollPromise = $interval poll, 5000
  $scope.$on '$destroy',  ->
    if angular.isDefined pollPromise
      $interval.cancel pollPromise
      pollPromise = undefined

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
    Errors.length = 0

    result = DeckParser.parse $scope.deck

    if result.errors.length == 0
      Api.generate { cards: result.cards , skipBasicLands: $scope.skipBasicLands }, (data)->
        $scope.link = "/docs/#{data.documentUrl}"
        Api.getRequestCount (data) ->
          $scope.requestCount = data.requestCount
        $timeout ->
          $scope.isGenerating = false
          $scope.hasLink = true
        , 1000
    else
      $scope.isGenerating = false
      Errors.push "error parsing deck"
      #for error in result.errors
      #  Errors.push "#{error.line} : #{error.message}"


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

app.controller 'mainController', ['$scope','$interval','$timeout','Errors','DeckParser','Api',mainController]

app.config ['$routeProvider',config]
