'use strict'

app = angular.module 'fhirface', [
  'ngCookies',
  'ngAnimate',
  'ngSanitize',
  'ngRoute',
  "ui.codemirror"
], ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/conformance',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/resources/:resourceType',
        templateUrl: '/views/resources/index.html'
        controller: 'ResourcesIndexCtrl'
      .when '/resources/:resourceType/new',
        templateUrl: '/views/resources/new.html'
        controller: 'ResourcesNewCtrl'
      .when '/resources/:resourceType/:id',
        templateUrl: '/views/resources/show.html'
        controller: 'ResourceCtrl'
      .when '/resources/:resourceType/:id/history',
        templateUrl: '/views/resources/history.html'
        controller: 'ResourcesHistoryCtrl'
      .otherwise
        redirectTo: '/'

app.run ($rootScope, fhir, menu)->
  $rootScope.fhir = fhir
  $rootScope.menu = menu

cropUuid = (id)->
  return "ups no uuid :(" unless id
  sid = id.substring(id.length - 6, id.length)
  "...#{sid}"

app.filter 'uuid', ()-> cropUuid

keyComparator = (key)->
 (a, b) ->
   switch
     when a[key] < b[key] then -1
     when a[key] > b[key] then 1
     else 0

app.filter 'profileTypes', ()->
  (xs)->
    (xs || []).map((i)->
      if i.code == 'ResourceReference'
        i.profile.split('/').pop()
      else
        i.code
    ).join(', ')

app.controller 'ConformanceCtrl', (menu, $scope, fhir) ->
  menu.build({}, 'conformance*')

  fhir.metadata (data)->
    $scope.resources = data.rest[0].resource.sort(keyComparator('type')) || []
    delete data.rest
    delete data.text
    $scope.conformance = data

app.controller 'ResourcesIndexCtrl', (menu, fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index*', 'new')

  $scope.query = {}

  rt = $routeParams.resourceType

  fhir.profile rt, (data)-> $scope.profile = data

  $scope.search = ()->
    fhir.search rt, $scope.query, (data, s, x, config) ->
        $scope.searchUri = config
        $scope.resources = data.entry || []

  $scope.search()

app.controller 'ResourcesNewCtrl', (menu, fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index', 'new*')

  $scope.resource = {}

  rt = $routeParams.resourceType

  $scope.save = ->
    fhir.create rt, $scope.resource.content, ()->
      $location.path("/resources/#{rt}")

  $scope.validate = ()->
    fhir.validate(rt, $scope.resource.content)

pretifyJson = (str)-> angular.toJson(angular.fromJson(str), true)

app.controller 'ResourceCtrl', (menu, fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams,'conformance', 'index', 'show*', 'history')

  rt = $routeParams.resourceType
  id = $routeParams.id

  loadResource = ()->
    fhir.read rt, id, (data, status, headers, config)->
      $scope.resource = { content: pretifyJson(data) }
      $scope.resourceContentLocation = headers('Content-Location')
      throw "content location required" unless $scope.resourceContentLocation

  loadResource()

  $scope.save = ->
    cl = $scope.resourceContentLocation
    res = $scope.resource.content
    fhir.update rt, id, cl, res, (data,status,headers,req)->
      $scope.resourceContentLocation = headers('content-location')

  $scope.destroy = ->
    if window.confirm("Destroy #{$scope.resource.id}?")
      fhir.delete rt, id, ()-> $location.path("/resources/#{rt}")

  $scope.validate = ()->
    res = $scope.resource.content
    fhir.validate(rt, id, res)

app.controller 'ResourcesHistoryCtrl', (menu, fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index', 'show', 'history*')

  fhir.history $routeParams.resourceType, $routeParams.id, (data) ->
    $scope.entries = data.entry
    $scope.history  = data
    delete $scope.history.entry
