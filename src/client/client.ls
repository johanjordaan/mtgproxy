_  = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

mainController = ($scope,$timeout,Api) ->
  $scope.deck = '''
  1 Duress
  1 Raging Goblin
  1 Wrath of God

  1 Duress
  '''

  $scope.link = ""
  $scope.status = ""
  $scope.requestCount = 0

  poll = ->
    Api.getRequestCount (data) ->
      $scope.requestCount = data.count
      $timeout ->
        poll
      ,3000
  poll!

  $scope.generate = ->
    $scope.status = "Generating..."
    Api.generate { cardList: JSON.stringify($scope.deck) }, (data)->
      $scope.link = "/docs/#{data.documentUrl}"
      Api.getRequestCount (data) ->
        $scope.requestCount = data.count
      $timeout ->
        $scope.status = "Download"
      , 1000

apiFactory = ($resource,ErrorHandler) ->
  do
    getRequestCount: (cb) ->
      $resource '/api/v1/requestcount', null
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


app = angular.module 'gameApp',['ngResource','ngRoute']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.value 'Errors',[]

app.controller 'errorController', ['$scope','Errors',errorController]

app.controller 'mainController', ['$scope','$timeout','Api',mainController]

app.config ['$routeProvider',config]
