require('file?name=index.html!../index.html')
require('file?name=fhir.json!../fhir.json')
require('../less/app.less')

URI = require('../../bower_components/uri.js/src/URI.js')

app = require('./module')
require('./fhir')
require('./views')

baseUrl = require('./baseurl')
oauthUrl = require('./oauthurl')()

app.config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/authorization',
        templateUrl: '/views/authorization.html'
        controller: 'AuthorizationCtrl'
      .when '/conformance',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/resources/Any',
        templateUrl: '/views/index.html'
        controller: 'IndexCtrl'
      .when '/resources/Any/history',
        templateUrl: '/views/history.html'
        controller: 'HistoryCtrl'
      .when '/resources/Any/tags',
        templateUrl: '/views/tags.html'
        controller: 'TagsCtrl'
      .when '/resources/Any/transaction',
        templateUrl: '/views/transaction.html'
        controller: 'TransactionCtrl'
      .when '/resources/Any/document',
        templateUrl: '/views/document.html'
        controller: 'DocumentCtrl'
      .when '/resources/:resourceType',
        templateUrl: '/views/index.html'
        controller: 'ResourcesIndexCtrl'
      .when '/resources/:resourceType/history',
        templateUrl: '/views/history.html'
        controller: 'ResourcesHistoryCtrl'
      .when '/resources/:resourceType/tags',
        templateUrl: '/views/tags.html'
        controller: 'ResourcesTagsCtrl'
      .when '/resources/:resourceType/new',
        templateUrl: '/views/new.html'
        controller: 'ResourcesNewCtrl'
      .when '/resources/:resourceType/:id',
        templateUrl: '/views/show.html'
        controller: 'ResourceCtrl'
      .when '/resources/:resourceType/:id/history',
        templateUrl: '/views/history.html'
        controller: 'ResourceHistoryCtrl'
      .when '/resources/:resourceType/:id/tags',
        templateUrl: '/views/tags.html'
        controller: 'ResourceTagsCtrl'
      .otherwise
        redirectTo: '/'

require('./menu')

identity = (x)-> x

rm = (x, xs)-> xs.splice(xs.indexOf(x),1)

NOTIFICATION_REMOVE_TIMEOUT = 2000

magic = {
  active: 0
  notifications: []
  error: null
  removeNotification: (i)->
    magic.notifications.splice(magic.notifications.indexOf(i), 1)
}

app.run ($rootScope, $appFhir, menu, $window, $location)->
  queryString = URI($window.location.search).query(true)
  $rootScope.oauth = {}

  if queryString.code
    $rootScope.oauth.code = queryString.code

  $location.path("/authorization") unless $rootScope.oauth.access_token

  magic = $appFhir
  $rootScope.fhir = magic
  $rootScope.menu = menu

app.config ($fhirProvider, $httpProvider)->
  $fhirProvider.baseUrl = baseUrl()
  $httpProvider.interceptors.push ($q, $timeout)->
    {
      request: (config) ->
        note = angular.copy(config)
        unless note.url.match(/^\/views\//)
          note.status = "..."
          note.config = config
          magic.notifications.push(note)
          magic.active += 1
          $timeout (()-> magic.removeNotification(note)), NOTIFICATION_REMOVE_TIMEOUT
        config
      response: (response) ->
        magic.active -= 1
        (magic.notifications.filter((n) -> n.config == response.config)[0] || {}).status = response.status
        response
      responseError: (rejection) ->
        console.error("error: ", rejection)
        magic.active -= 1
        (magic.notifications.filter((n) -> n.config == rejection.config)[0] || {}).status = rejection.status
        magic.error = rejection.data || "Server error #{rejection.status} while loading: #{rejection.config.url}"
        $q.reject(rejection)
    }
cropUuid = (id)->
  return "ups no uuid :(" unless id
  sid = id.substring(id.length - 6, id.length)
  "...#{sid}"

app.filter 'uuid', ()-> cropUuid

app.filter 'urlFor', ()->
  (res)->
    parts = res.id.split(/\//)
    id = parts[parts.length - 1]
    "#/resources/#{res.content.resourceType}/#{id}"

_getByXpath = (acc, entry, xpath)->
  if xpath.length < 1 and  entry?
    acc.push(entry)
  else
    key = xpath[0]
    val = entry[key]
    newpath = xpath.slice(1, xpath.length)
    if val?
      if angular.isArray(val)
        _getByXpath(acc, aval, newpath) for aval in val
      else if angular.isObject(val)
        _getByXpath(acc, val, newpath)
      else if newpath.length < 1 and val?
        acc.push(val)

_searchPreview = (entry, params)->
  res = []
  for p in params
    if p.xpath
      path = p.xpath.split('/')
      path.shift()
      acc = []
      _getByXpath(acc,entry.content, path)
      res.push "#{p.xpath}: #{JSON.stringify(acc)}"
  res.join('; ')

app.filter 'searchPreview', ()->
  (entry, query)->
    _searchPreview(entry, query.params)

cropId = (id)->
  return "ups no uuid :(" unless id
  arr = id.split('/')
  arr[arr.length - 1]

app.filter 'id', ()-> cropId

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

app.controller 'AuthorizationCtrl', (menu, $scope, $fhir, $rootScope) ->
  menu.build({}, 'authorization*')

  $scope.oauth = $rootScope.oauth
  # $window.location.href = oauthUrl.authorize
  $scope.authorizeUri = URI(oauthUrl.authorize)
    .setQuery({
      scope: 'foo',
      response_type: 'code',
      client_id: 'foo',
      redirect_uri: 'http://192.168.0.39:53000'
    }).href()

app.controller 'ConformanceCtrl', (menu, $scope, $fhir) ->
  menu.build({}, 'conformance*')

  $fhir.conformance success: (data)->
    $scope.resources = [{type: 'Any'}].concat data.rest[0].resource.sort(keyComparator('type')) || []
    delete data.rest
    delete data.text
    $scope.conformance = data

# FIXME: this controller do not work
app.controller 'IndexCtrl', (menu, $fhir, $appFhirParams, $appFhirSearch, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index_all*', 'transaction', 'document', 'history_all', 'tags_all')

  rt = 'Alert'

  $scope.searchResourceType = rt
  $scope.searchState = 'search'
  $scope.searchFilter = ''
  $scope.query = {searchParam: []}

  $scope.addParam = (p)->
    if $scope.searchState == 'addSortParam'
      $scope.query.addSortParam(p)
    if $scope.searchState == 'addRef'
      $scope.query.addInclude(p)
    else
      $scope.query.addSearchParam(p)
      $scope.searchFilter = ''
    $scope.searchState="search"

  $fhir.profile type: rt, success: (data)->
    $scope.profile = data
    $scope.query = $appFhirParams(data)

  $scope.typeFilterSearchParams = (type, filter)->
    $appFhirSearch.typeFilterSearchParams(type, filter)

  $scope.search = ()->
    $fhir.search type: rt, query: {}, success: (data, s, x, config)->
      console.log($scope.searchSummary)
      $scope.resources = data.entry || []

app.controller 'ResourcesIndexCtrl', (menu, $fhir, $appFhirParams, $appFhirSearch, $appFhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index*', 'new', 'history_type', 'tags_type')

  rt = $routeParams.resourceType

  $scope.searchResourceType = rt
  $scope.searchState = 'search'
  $scope.searchFilter = ''

  $scope.addParam = (p)->
    if $scope.searchState == 'addSortParam'
      $scope.query.addSortParam(p)
    if $scope.searchState == 'addRef'
      $scope.query.addInclude(p)
    else
      $scope.query.addSearchParam(p)
      $scope.searchFilter = ''
    $scope.searchState="search"

  $fhir.profile type: rt, success: (data)->
    $scope.profile = data
    $scope.query = $appFhirParams(data)
    $scope.search()

  $scope.typeFilterSearchParams = (type, filter)->
    $appFhirSearch.typeFilterSearchParams(type, filter)

  # TODO: refactor to fhir.js api
  $scope.search = ()->
    unless $scope.query
      console.error('Search query not initailized')
      return
    start = new Date()
    $appFhir.search rt, $scope.query, (data, s, x, config)->
      $scope.searchSummary =  {title: data.title,  time: (new Date() - start)}
      $scope.resources = data.entry || []

initTags = ($scope)->
  $scope.tags = []

  schemes = {
   Security: "http://hl7.org/fhir/tag/security",
   Profile: "http://hl7.org/fhir/tag/profile",
   Tag: "http://hl7.org/fhir/tag/tag"
  }

  $scope.removeTag = (x)->
    tags = $scope.tags
    tags.splice(tags.indexOf(x),1)

  $scope.clearTags = ()->
    $scope.tags = []

  mkAdder = (schem)->
    ()-> $scope.tags.push({scheme: schem})

  $scope["add#{k}"] = mkAdder(s) for k,s of schemes

app.controller 'ResourcesNewCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index', 'new*')

  $scope.resource = {}
  initTags($scope)

  rt = $routeParams.resourceType

  $scope.save = ->
    tags = $scope.tags.filter((i)-> i.term)
    $fhir.create entry: {content: angular.fromJson($scope.resource.content), category: tags}, success: ()->
      $location.path("/resources/#{rt}")

  $scope.validate = ()->
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    $fhir.validate entry: {content: angular.fromJson(res), category: tags}, success: ()->
      #alert('Valid')

pretifyJson = (str)-> angular.toJson(angular.fromJson(str), true)

app.controller 'ResourceCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams,'conformance', 'index', 'show*', 'history', 'tags')

  rt = $routeParams.resourceType
  id = $routeParams.id
  initTags($scope)

  loadResource = ()->
    $fhir.read id: (rt + '/' + id), success: (data)->
      $scope.tags = data.category
      $scope.resource = { id: id, content: pretifyJson(data.content) }
      $scope.resourceContentLocation = data.id
      throw "content location required" unless $scope.resourceContentLocation

  loadResource()

  $scope.save = ->
    cl = $scope.resourceContentLocation
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    $fhir.update entry: {id: cl, content: angular.fromJson(res), category: tags}, success: (data)->
      $scope.resourceContentLocation = data.id
      throw "content location required" unless $scope.resourceContentLocation

  $scope.destroy = ->
    if window.confirm("Destroy #{$scope.resource.id}?")
      $fhir.delete entry: {id: $scope.resourceContentLocation}, success: ()-> $location.path("/resources/#{rt}")

  $scope.removeAllTags = ()->
    $fhir.removeTags type: rt, id: id, success: ()->
      $scope.tags = []

  $scope.affixResourceTags = ()->
    $fhir.affixTags type: rt, id: id, tags: $scope.tags, succes: (tagList)->
      $scope.tags = tagList.category

  $scope.validate = ()->
    cl = $scope.resourceContentLocation
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    $fhir.validate entry: {content: angular.fromJson(res), category: tags}, success: ()->
      #alert('Valid')

app.controller 'ResourceHistoryCtrl', (menu, $scope, $routeParams, $fhir) ->
  menu.build($routeParams, 'conformance', 'index', 'show', 'history*')

  $fhir.history
    type: $routeParams.resourceType
    id: $routeParams.id
    success: (data)->
      $scope.entries = data.entry
      $scope.history = data
      delete $scope.history.entry

app.controller 'ResourcesHistoryCtrl', (menu, $scope, $routeParams, $fhir) ->
  menu.build($routeParams, 'conformance', 'index', 'history_type*')

  $fhir.history
    type: $routeParams.resourceType
    success: (data)->
      $scope.entries = data.entry
      $scope.history = data
      delete $scope.history.entry

app.controller 'HistoryCtrl', (menu, $scope, $routeParams, $fhir) ->
  menu.build($routeParams, 'conformance', 'index_all', 'history_all*')

  $fhir.history
    success: (data)->
      $scope.entries = data.entry
      $scope.history = data
      delete $scope.history.entry

app.controller 'TagsCtrl', (menu, $scope, $routeParams, $fhir) ->
  menu.build($routeParams, 'conformance', 'index_all', 'tags_all*')

  $fhir.tags success: (data) ->
    $scope.tags = data

app.controller 'ResourcesTagsCtrl', (menu, $fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index', 'tags_type*')

  $fhir.tags type: $routeParams.resourceType, success: (data) ->
    $scope.tags = data

app.controller 'ResourceTagsCtrl', (menu, $fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index', 'show', 'tags*')

  $fhir.tags
    type: $routeParams.resourceType,
    id: $routeParams.id, success: (data) ->
      $scope.tags = data

app.controller 'TransactionCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index_all', 'transaction*')

  $scope.bundle = {}
  $scope.save = ->
    $fhir.transaction bundle: $scope.bundle.content, success: ->
      $location.path("/resources/Any")

app.controller 'DocumentCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index_all', 'document*')

  $scope.bundle = {}

  $scope.save = ->
    $fhir.document bundle: $scope.bundle.content, success: ->
      $location.path("/resources/Any")
