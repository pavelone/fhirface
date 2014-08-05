angular.module('fhirface').provider 'search', ()->
  cache = {
    searchCache: {}
    profileCache: {}
    chainsCache: {}
    searchTypes: []
  }

  $get: (fhir, fhirParams)->
    
    fillProfileCache = (type)->
      fhir.profile type, (data)->
        profile = fhirParams(data)
        cache.profileCache[type] = profile.searchParam
        cache.chainsCache[type] = profile.chainType

    fhir.metadata (data)->
      cache.searchTypes = (data.rest[0].resource.sort(keyComparator('type')) || []).map (i)-> i.type

    typeSearchParams = (type)->
      c = cache.profileCache[type]
      if c
        c
      else
        cache.profileCache[type] = []
        fillProfileCache(type)
        console.log('profile ' + type)
        []

    typeChainTypes = (type)->
      c = cache.chainsCache[type]
      if c
        c
      else
        cache.chainsCache[type] = {}
        fillProfileCache(type)
        console.log('chain ' + type)
        {}

    filterParams = (params, filter)->
      regexp = RegExp(filter.replace(/(.)/g, "$1.*"), "i")
      params.filter (p) -> regexp.test(p.name)

    typeChainParams = (type)->
      (typeSearchParams(type) || []).filter (p)-> p.type == 'reference'

    typeReferenceTypes = (type, ref)->
      typeChainTypes(type)[ref] || cache.searchTypes

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
          cache.searchCache[p.name] ||= p
        .slice(0, 30)
    }

    provider