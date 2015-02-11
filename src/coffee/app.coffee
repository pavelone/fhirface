require('file?name=index.html!../index.html')
require('file?name=fhir.json!../fhir.json')
require('../less/app.less')

URI = require('../../bower_components/uri.js/src/URI.js')

app = require('./module')
require('./fhir')
require('./views')

baseUrl = require('./baseurl')
oauthConfig = require('./oauth_config')()

require('./routes')
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
  if oauthConfig.response_type
    queryString = URI($window.location.search).query(true)
    code = $location.search().code || queryString.code
    accessToken = $location.search().access_token || queryString.access_token
    $rootScope.oauth = {}
    $rootScope.oauth.code = code if code
    $rootScope.oauth.access_token = accessToken if accessToken
    if oauthConfig.response_type == 'code'

      # FIXME: REMOVE ME!!! Remove after new server demo (with backend)
      #        will created.
      if $rootScope.oauth.code && !$rootScope.oauth.access_token
        $location.path('/redirect')
      else if !$rootScope.oauth.code
        $location.path('/authorization')

    else if oauthConfig.response_type == 'token'
      if !$rootScope.oauth.access_token
        $location.path('/authorization')

  magic = $appFhir
  $rootScope.fhir = magic
  $rootScope.menu = menu

app.config ($fhirProvider, $httpProvider) ->
  # could you do it in a service???
  $fhirProvider.baseUrl = baseUrl()
  $httpProvider.interceptors.push ($q, $timeout, $rootScope) ->
    request: (config) ->
      note = angular.copy(config)
      uri = URI(config.url)
      unless uri.path().match(/^\/(views|oauth)/)
        note.status = "..."
        note.config = config
        magic.notifications.push(note)
        magic.active += 1
        if oauthConfig.response_type
          config.url = uri.addQuery(
            access_token: $rootScope.oauth.access_token
          ).toString()
        $timeout (()-> magic.removeNotification(note)),
          NOTIFICATION_REMOVE_TIMEOUT
      config
    response: (response) ->
      magic.active -= 1
      (magic.notifications.filter((n) -> n.config == response.config)[0] || {})
        .status = response.status
      response
    responseError: (rejection) ->
      console.error("error: ", rejection)
      magic.active -= 1
      (magic.notifications.filter((n) -> n.config == rejection.config)[0] || {})
        .status = rejection.status
      magic.error = rejection.data ||
        "Server error #{rejection.status} while loading: #{rejection.config.url}"
      $q.reject(rejection)

cropUuid = (id)->
  return "ups no uuid :(" unless id
  sid = id.substring(id.length - 6, id.length)
  "...#{sid}"

app.filter 'uuid', ()-> cropUuid

app.filter 'urlFor', ()->
  (res)->
    id = res.id
    "#/resources/#{res.resourceType}/#{id}"

_getByXpath = (acc, entry, xpath)->
  if xpath.length < 1 and entry?
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

_searchPreview = (resource, params)->
  res = []
  for k,p of params
    if p and p.xpath
      path = p.xpath.replace(/f:/g,'').split('/')
      path.shift()
      acc = []
      _getByXpath(acc,resource, path)
      res.push "#{path.join('.')}: #{JSON.stringify(acc)}"
  res.join('; ')

app.filter 'searchPreview', ()->
  (entry, params)->
    _searchPreview(entry, params)

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

app.controller 'AuthorizationCtrl', (menu, $scope, $rootScope) ->
  menu.build({}, 'authorization*')

  # TODO: To remove this debuging output (and from view authorization.html).
  $scope.debugOauth = {}
  $scope.debugOauth.config = oauthConfig
  $scope.debugOauth.variables = $rootScope.oauth

  $scope.authorizeUri = URI(oauthConfig.authorize_uri)
    .setQuery(
      client_id: oauthConfig.client_id
      redirect_uri: oauthConfig.redirect_uri
      response_type: oauthConfig.response_type
      scope: oauthConfig.scope
    ).toString()

app.controller 'AuthorizationRedirectCtrl',
  (menu, $scope, $rootScope, $http, $location) ->
    menu.build({}, 'authorizationRedirect*')

    # TODO: To remove this debuging output (and from view
    # authorization_redirect.html).
    $scope.debugOauth = {}
    $scope.debugOauth.config = oauthConfig
    $scope.debugOauth.variables = $rootScope.oauth

    if oauthConfig.response_type == 'code'
      $http(
        method: 'POST'
        url: oauthConfig.access_token_uri
        headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        data: URI('').setQuery(
          client_id: oauthConfig.client_id
          client_secret: oauthConfig.client_secret
          code: $rootScope.oauth.code
          redirect_uri: oauthConfig.redirect_uri
        ).query()
      ).success((data) ->
        $rootScope.oauth.access_token = data.access_token
        $rootScope.oauth.scope = data.scope
        $location.path('/')
      ).error (data) ->
        console.log 'OAuth2 access_token getting error', data
    else if oauthConfig.response_type == 'token'
      $location.path('/')

app.controller 'ConformanceCtrl', (menu, $scope, $fhir) ->
  menu.build({}, 'conformance*')

  $fhir.conformance success: (data)->
    $scope.resources = [{type: 'Any'}].concat data.rest[0].resource.sort(keyComparator('type')) || []
    delete data.rest
    delete data.text
    $scope.conformance = data

#FIXME: this controller do not work
app.controller 'IndexCtrl', (menu, $fhir, $appFhirParams, $appFhirSearch, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index_all*', 'transaction', 'document', 'history_all', 'tags_all')

parseParams = (str, paramsIdx)->
  res = {}
  str.split('&')
    .map((x)->  x.trim())
    .forEach (pair)->
      [k,v] = pair.split('=').map((x)-> x.trim())
      res[k]=paramsIdx[k]
  res

app.controller 'ResourcesIndexCtrl', (menu, $fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index*', 'new', 'history_type', 'tags_type')

  rt = $routeParams.resourceType

  $scope.query = {}
  $scope.searchResourceType = rt

  $scope.paramsIdx = {}
  $fhir.search
    type: 'SearchParameter'
    query: {base: rt}
    success: (sp)->
      $scope.params = sp.entry.map((x)-> x.resource) || []
      $scope.paramsIdx = $scope.params.reduce(((acc,x)-> acc[x.name]=x; acc), {})

  $scope.search = ()->
    start = new Date()
    # query = {_count: 20}
    query = '_count=20'
    query = $scope.query.q if $scope.query.q
    $scope.searched = parseParams(query, $scope.paramsIdx)
    $fhir.search
      type: rt
      query: query
      success: (data)->
        $scope.searchSummary =  {title: data.title,  time: (new Date() - start)}
        $scope.resources = data.entry.map((x)-> x.resource)
      error: (err)->
        console.error(err)

  $scope.search()

app.controller 'ResourcesNewCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index', 'new*')

  $scope.resource = {}

  rt = $routeParams.resourceType

  $scope.save = ->
    $fhir.create
      resource: angular.fromJson($scope.resource.content)
      success: (data)->
        $location.path("/resources/#{data.resourceType}/#{data.id}")

  $scope.validate = ()->
    res = angular.fromJson($scope.resource.content)
    $fhir.validate
      resource: res
      success: (data)->
        console.log(data)

pretifyJson = (str)-> angular.toJson(angular.fromJson(str), true)

app.controller 'ResourceCtrl', (menu, $fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams,'conformance', 'index', 'show*', 'history', 'tags')

  rt = $routeParams.resourceType
  id = $routeParams.id


  loadResource = ()->
    $fhir.read id: id, resourceType: rt, success: (data)->
      $scope.resource = { id: id, content: pretifyJson(data), resource: data }
      $scope.resourceContentLocation = data.id
      throw "content location required" unless $scope.resourceContentLocation

  loadResource()

  $scope.save = ->
    res = angular.fromJson($scope.resource.content)
    $fhir.update
      resource: res
      success: (data)->
        $scope.resource = { id: data.id, content: pretifyJson(data) }

  $scope.destroy = ->
    res = angular.fromJson($scope.resource.content)
    if window.confirm("Destroy #{res.id}")
      $fhir.delete
        resource: res
        success: ()-> $location.path("/resources/#{rt}")

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
