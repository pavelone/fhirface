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
      .when '/resources/Any',
        templateUrl: '/views/resources/index.html'
        controller: 'IndexCtrl'
      .when '/resources/:resourceType',
        templateUrl: '/views/resources/index.html'
        controller: 'ResourcesIndexCtrl'
      .when '/resources/Any/history',
        templateUrl: '/views/resources/history.html'
        controller: 'HistoryCtrl'
      .when '/resources/:resourceType/history',
        templateUrl: '/views/resources/history.html'
        controller: 'ResourcesHistoryCtrl'
      .when '/resources/:resourceType/new',
        templateUrl: '/views/resources/new.html'
        controller: 'ResourcesNewCtrl'
      .when '/resources/:resourceType/:id',
        templateUrl: '/views/resources/show.html'
        controller: 'ResourceCtrl'
      .when '/resources/:resourceType/:id/history',
        templateUrl: '/views/resources/history.html'
        controller: 'ResourceHistoryCtrl'
      .otherwise
        redirectTo: '/'

identity = (x)-> x

rm = (x, xs)-> xs.splice(xs.indexOf(x),1)

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
  fhir.tags (data)->
    # console.log("TAGS", data)
    $scope.tags = data

  fhir.metadata (data)->
    $scope.resources = [{type: 'Any'}].concat data.rest[0].resource.sort(keyComparator('type')) || []
    delete data.rest
    delete data.text
    $scope.conformance = data

app.controller 'IndexCtrl', (menu, fhir, fhirParams, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index_all*', 'history_all')

  rt = 'Alert'

  $scope.searchState = 'search'
  $scope.searchFilter = ''
  $scope.searchResourceType = rt
  $scope.query = {searchParam: []}
  $scope.searchCache = {}
  $scope.profileCache = {}
  $scope.chainsCache = {}
  $scope.searchTypes = []

  $scope.fillProfileCache = (type)->
    fhir.profile type, (data)->
      profile = fhirParams(data)
      $scope.profileCache[type] = profile.searchParam
      $scope.chainsCache[type] = profile.chainType

  fhir.metadata (data)->
    $scope.searchTypes = (data.rest[0].resource.sort(keyComparator('type')) || []).map (i)-> i.type
    # for t in $scope.searchTypes
    #  $scope.fillProfileCache(t)

  $scope.addParam = (p)->
    if $scope.searchState == 'addSortParam'
      $scope.query.addSortParam(p)
    if $scope.searchState == 'addRef'
      $scope.query.addInclude(p)
    else
      $scope.query.addSearchParam(p)
      $scope.searchFilter = ''
    $scope.searchState="search"

  fhir.profile rt, (data)->
    $scope.profile = data
    $scope.query = fhirParams(data)

  $scope.typeSearchParams = (type)->
    cache = $scope.profileCache[type]
    if cache
      cache
    else
      $scope.profileCache[type] = []
      $scope.fillProfileCache(type)
      console.log('profile ' + type)
      []

  $scope.typeChainTypes = (type)->
    cache = $scope.chainsCache[type]
    if cache
      cache
    else
      $scope.chainsCache[type] = {}
      $scope.fillProfileCache(type)
      console.log('chain ' + type)
      {}

  $scope.filterParams = (params, filter)->
    regexp = RegExp(filter.replace(/(.)/g, "$1.*"), "i")
    params.filter (p) -> regexp.test(p.name)

  $scope.typeChainParams = (type)->
    ($scope.typeSearchParams(type) || []).filter (p)-> p.type == 'reference'

  $scope.typeReferenceTypes = (type, ref)->
    $scope.typeChainTypes(type)[ref] || $scope.searchTypes

  $scope.typeFilterChainParams = (type, filter)->
    chains = $scope.typeChainParams(type).map (p)->
      $scope.typeReferenceTypes(type, p.name).map (t)->
        {name: p.name + ':' + t, type: t}
    params = chains.concat([[], []]).reduce (x, y)-> x.concat y
    $scope.filterParams(params, filter)

  $scope.typeFilterParams = (type, parts)->
    if parts.length < 2
      $scope.filterParams($scope.typeSearchParams(type) || [], parts[0] || '')
    else
      next = $scope.typeFilterChainParams(type, parts[0]).map (c)->
        $scope.typeFilterParams(c.type, parts.slice(1)).map (p)->
          {name: c.name + '.' + p.name, type: p.type, documentation: p.documentation, xpath: p.xpath}
      next.concat([[], []]).reduce (x, y)-> x.concat(y)

  $scope.typeFilterSortedParams = (type, filter)->
    $scope.typeFilterParams(type, filter.split(".")).sort (a, b)->
      a.name.localeCompare(b.name)

  $scope.typeFilterSearchParams = (type, filter)->
    one = $scope.typeFilterSortedParams(type, filter)
    two = $scope.typeFilterSortedParams(type, filter + ".")
    one.concat(two).map (p)->
      $scope.searchCache[p.name] ||= p
    .slice(0, 30)

  $scope.search = ()->
    fhir.search rt, $scope.query, (data, s, x, config) ->
        $scope.searchUri = config
        $scope.resources = data.entry || []

app.controller 'ResourcesIndexCtrl', (menu, fhir, fhirParams, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index*', 'new', 'history_type')

  rt = $routeParams.resourceType

  $scope.searchState = 'search'
  $scope.searchFilter = ''
  $scope.searchResourceType = rt
  $scope.query = {searchParam: []}
  $scope.searchCache = {}
  $scope.profileCache = {}
  $scope.chainsCache = {}
  $scope.searchTypes = []

  $scope.fillProfileCache = (type)->
    fhir.profile type, (data)->
      profile = fhirParams(data)
      $scope.profileCache[type] = profile.searchParam
      $scope.chainsCache[type] = profile.chainType

  fhir.metadata (data)->
    $scope.searchTypes = (data.rest[0].resource.sort(keyComparator('type')) || []).map (i)-> i.type
    # for t in $scope.searchTypes
    #  $scope.fillProfileCache(t)

  $scope.addParam = (p)->
    if $scope.searchState == 'addSortParam'
      $scope.query.addSortParam(p)
    if $scope.searchState == 'addRef'
      $scope.query.addInclude(p)
    else
      $scope.query.addSearchParam(p)
      $scope.searchFilter = ''
    $scope.searchState="search"

  fhir.profile rt, (data)->
    $scope.profile = data
    $scope.query = fhirParams(data)

  $scope.typeSearchParams = (type)->
    cache = $scope.profileCache[type]
    if cache
      cache
    else
      $scope.profileCache[type] = []
      $scope.fillProfileCache(type)
      console.log('profile ' + type)
      []

  $scope.typeChainTypes = (type)->
    cache = $scope.chainsCache[type]
    if cache
      cache
    else
      $scope.chainsCache[type] = {}
      $scope.fillProfileCache(type)
      console.log('chain ' + type)
      {}

  $scope.filterParams = (params, filter)->
    regexp = RegExp(filter.replace(/(.)/g, "$1.*"), "i")
    params.filter (p) -> regexp.test(p.name)

  $scope.typeChainParams = (type)->
    ($scope.typeSearchParams(type) || []).filter (p)-> p.type == 'reference'

  $scope.typeReferenceTypes = (type, ref)->
    $scope.typeChainTypes(type)[ref] || $scope.searchTypes

  $scope.typeFilterChainParams = (type, filter)->
    chains = $scope.typeChainParams(type).map (p)->
      $scope.typeReferenceTypes(type, p.name).map (t)->
        {name: p.name + ':' + t, type: t}
    params = chains.concat([[], []]).reduce (x, y)-> x.concat y
    $scope.filterParams(params, filter)

  $scope.typeFilterParams = (type, parts)->
    if parts.length < 2
      $scope.filterParams($scope.typeSearchParams(type) || [], parts[0] || '')
    else
      next = $scope.typeFilterChainParams(type, parts[0]).map (c)->
        $scope.typeFilterParams(c.type, parts.slice(1)).map (p)->
          {name: c.name + '.' + p.name, type: p.type, documentation: p.documentation, xpath: p.xpath}
      next.concat([[], []]).reduce (x, y)-> x.concat(y)

  $scope.typeFilterSortedParams = (type, filter)->
    $scope.typeFilterParams(type, filter.split(".")).sort (a, b)->
      a.name.localeCompare(b.name)

  $scope.typeFilterSearchParams = (type, filter)->
    one = $scope.typeFilterSortedParams(type, filter)
    two = $scope.typeFilterSortedParams(type, filter + ".")
    one.concat(two).map (p)->
      $scope.searchCache[p.name] ||= p
    .slice(0, 30)

  $scope.search = ()->
    fhir.search rt, $scope.query, (data, s, x, config) ->
        $scope.searchUri = config
        $scope.resources = data.entry || []

  # $scope.search()

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

app.controller 'ResourcesNewCtrl', (menu, fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams, 'conformance', 'index', 'new*')

  $scope.resource = {}
  initTags($scope)

  rt = $routeParams.resourceType

  $scope.save = ->
    tags = $scope.tags.filter((i)-> i.term)
    fhir.create rt, $scope.resource.content, tags, ()->
      $location.path("/resources/#{rt}")

  $scope.validate = ()->
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    fhir.validate(rt, null, null, res, tags)

pretifyJson = (str)-> angular.toJson(angular.fromJson(str), true)

app.controller 'ResourceCtrl', (menu, fhir, $scope, $routeParams, $location) ->
  menu.build($routeParams,'conformance', 'index', 'show*', 'history')

  rt = $routeParams.resourceType
  id = $routeParams.id
  initTags($scope)

  loadResource = ()->
    fhir.read rt, id, (contentLoc, res, tags)->
      $scope.tags = tags
      $scope.resource = { id: id, content: pretifyJson(res) }
      $scope.resourceContentLocation = contentLoc
      throw "content location required" unless contentLoc

  loadResource()

  $scope.save = ->
    cl = $scope.resourceContentLocation
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    fhir.update rt, id, cl, res, tags, (data,status,headers,req)->
      $scope.resourceContentLocation = headers('content-location')

  $scope.destroy = ->
    if window.confirm("Destroy #{$scope.resource.id}?")
      fhir.delete rt, id, ()-> $location.path("/resources/#{rt}")

  $scope.removeAllTags = ()->
    fhir.removeResourceTags rt, id, ()->
      $scope.tags = []

  $scope.affixResourceTags = ()->
    fhir.affixResourceTags rt, id, $scope.tags, (tagList)->
      $scope.tags = tagList.category

  $scope.validate = ()->
    cl = $scope.resourceContentLocation
    res = $scope.resource.content
    tags = $scope.tags.filter((i)-> i.term)
    fhir.validate(rt, id, cl, res, tags)

app.controller 'ResourceHistoryCtrl', (menu, fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index', 'show', 'history*')

  fhir.history $routeParams.resourceType, $routeParams.id, (data) ->
    $scope.entries = data.entry
    $scope.history  = data
    delete $scope.history.entry

app.controller 'ResourcesHistoryCtrl', (menu, fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index', 'history_type*')

  fhir.history_type $routeParams.resourceType, (data) ->
    $scope.entries = data.entry
    $scope.history  = data
    delete $scope.history.entry

app.controller 'HistoryCtrl', (menu, fhir, $scope, $routeParams) ->
  menu.build($routeParams, 'conformance', 'index_all', 'history_all*')

  fhir.history_all (data)->
    $scope.entries = data.entry
    $scope.history  = data
    delete $scope.history.entry