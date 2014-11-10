keyComparator = (key)->
 (a, b) ->
   switch
     when a[key] < b[key] then -1
     when a[key] > b[key] then 1
     else 0

angular.module('ng-fhir').provider '$fhirSearch', ()->
  cache = {
    type: []
    param: {}
    chain: {}
    search: {}
  }

  $get: ($fhir, $fhirParams)->

    $fhir.metadata (data)->
      cache.type = (data.rest[0].resource.sort(keyComparator('type')) || []).map (i)-> i.type

    fillCache = (type)->
      $fhir.profile type, (data)->
        profile = $fhirParams(data)
        cache.param[type] = profile.searchParam
        cache.chain[type] = profile.chainType

    typeSearchParams = (type)->
      c = cache.param[type]
      if c
        c
      else
        cache.param[type] = []
        fillCache(type)
        # console.log('profile ' + type)
        []

    typeChainTypes = (type)->
      c = cache.chain[type]
      if c
        c
      else
        cache.chain[type] = {}
        fillCache(type)
        # console.log('chain ' + type)
        {}

    filterParams = (params, filter)->
      regexp = RegExp(filter.replace(/(.)/g, "$1.*"), "i")
      params.filter (p) -> regexp.test(p.name)

    typeChainParams = (type)->
      (typeSearchParams(type) || []).filter (p)-> p.type == 'reference'

    typeReferenceTypes = (type, ref)->
      typeChainTypes(type)[ref] || cache.type

    typeFilterChainParams = (type, filter)->
      chains = typeChainParams(type).map (p)->
        typeReferenceTypes(type, p.name).map (t)->
          {name: p.name + ':' + t, type: t}
      params = chains.concat([[], []]).reduce (x, y)-> x.concat y
      filterParams(params, filter)

    typeFilterParams = (type, parts)->
      if parts.length < 2
        filterParams(typeSearchParams(type) || [], parts[0] || '')
      else
        next = typeFilterChainParams(type, parts[0]).map (c)->
          typeFilterParams(c.type, parts.slice(1)).map (p)->
            {name: c.name + '.' + p.name, type: p.type, documentation: p.documentation, xpath: p.xpath}
        next.concat([[], []]).reduce (x, y)-> x.concat(y)

    typeFilterSortedParams = (type, filter)->
      typeFilterParams(type, filter.split(".")).sort (a, b)->
        a.name.localeCompare(b.name)

    provider = {
      cache: cache

      typeFilterSearchParams: (type, filter)->
        one = typeFilterSortedParams(type, filter)
        two = typeFilterSortedParams(type, filter + ".")
        one.concat(two).map (p)->
          cache.search[p.name] ||= p
        .slice(0, 30)
    }

    provider
