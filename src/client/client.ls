_  = require 'prelude-ls'

errorController = ($scope,Errors) ->
  $scope.errors = Errors

  $scope.clear = ->
    Errors.length = 0

menuController = ($scope,$location) ->
  $scope.navigate = (destination) ->
    $location.path destination

  $scope.isSelected = (destination) ->

quizController = ($scope,Api,State) ->
  $scope.State = State

  $scope.question = do
    question:"???"

  $scope.answer = false

  if !State.CurrentQuestion?
    Api.getQuestion { token:"johan",sets:State.selectedSets }, (data) ->
      $scope.question = data
      State.CurrentQuestion = data
      $scope.image = "background-image: url(http://mtgimage.com/set/#{data.set_code}/#{data.question}-crop.jpg);"
  else
    $scope.question = State.CurrentQuestion

  $scope.submitAnswer = (index) ->
    Api.answerQuestion do
      token: "johan"
      question_id: $scope.question.id
      answer_index: index
      ,(data) ->

        $scope.result = {}  
        if data.correct
          $scope.result.text = "Correct"
          $scope.result.correct = true
          $scope.result.incorrect = false
        else
          $scope.result.text = "Incorrect"
          $scope.result.correct = false
          $scope.result.incorrect = true

        $scope.result.text = $scope.result.text + ",the answer was : #{$scope.question.options[data.correct_answer_index]}"
        $scope.answer = true

  $scope.next = ->
    Api.getQuestion { token:"johan",sets:State.selectedSets }, (data) ->
      $scope.question = data
      State.CurrentQuestion = data
      $scope.image = "background-image: url(http://mtgimage.com/set/#{data.set_code}/#{data.question}-crop.jpg);"
      $scope.answer = false

  $scope.showAnswer = ->
    $scope.answer

  $scope.showQuestion = ->
    !$scope.answer


settingsController = ($scope,Api,State) ->
  $scope.state = State

  switch State.sets?
  | true =>
  | otherwise =>
    Api.getSets (data) ->
      State.sets = data

  $scope.toggleSetSelection = (set_code) ->
    switch $scope.isSelected set_code
    | true =>
      switch State.selectedSets.length > 1
      | false =>
      | otherwise =>
        State.selectedSets = State.selectedSets |> _.filter (item) ->
          item != set_code
    | otherwise =>
      State.selectedSets.push set_code

  $scope.isSelected = (set_code) ->
    set_code in State.selectedSets





statsController = ($scope,Api,State) ->

userController = ($scope,Api,State) ->


apiFactory = ($resource,ErrorHandler) ->
  do
    getSets: (cb) ->
      $resource '/api/v1/sets', null
      .query {}, {}, cb, ErrorHandler


    getQuestion: (data, cb) ->
      $resource '/api/v1/questions', null
      .save {}, data, cb, ErrorHandler

    answerQuestion: (data, cb) ->
      $resource '/api/v1/answers', null
      .save {}, data, cb, ErrorHandler

errorHandlerFactory = (Errors) ->
  (err) ->
    Errors.push err.data.message

config = ($routeProvider) ->
  $routeProvider
  .when '/home', do
    templateUrl: 'quiz.html'
    controller: 'quizController'

  .when '/user', do
    templateUrl: 'user.html'
    controller: 'userController'

  .when '/settings', do
    templateUrl: 'settings.html'
    controller: 'settingsController'

  .when '/stats', do
    templateUrl: 'stats.html'
    controller: 'statsController'

  .otherwise do
    redirectTo: '/home'


app = angular.module 'gameApp',['ngResource','ngRoute']

app.factory 'Api',['$resource','ErrorHandler',apiFactory]
app.factory 'ErrorHandler',['Errors',errorHandlerFactory]
app.value 'Errors',[]
app.value 'State', do
  selectedSets: ['JOU']

app.controller 'errorController', ['$scope','Errors',errorController]
app.controller 'menuController', ['$scope','$location',menuController]

app.controller 'quizController', ['$scope','Api','State',quizController]
app.controller 'settingsController', ['$scope','Api','State',settingsController]
app.controller 'statsController', ['$scope','Api','State',statsController]
app.controller 'userController', ['$scope','Api','State',userController]


app.config ['$routeProvider',config]
