NOTIFICATION_REMOVE_TIMEOUT = 2000
angular.module('fhirface').provider 'fhir', ()->
  buildTags = (tags)->
    tags.filter((i)-> i.term)
      .map((i)-> "#{i.term}; scheme=\"#{i.scheme}\"; label=\"#{i.label}\"")
      .join(",")

  addKey = (acc, str)->
    return unless str
    pair = str.split("=").map($.trim)
    val = pair[1].replace(/(^"|"$)/g,'')
    acc[pair[0]] = val if val
    acc

  extractTags = (categoryHeader)->
    return [] unless categoryHeader
    categoryHeader.split(',').map (x)->
      parts = $.trim(x).split(';').map($.trim)
      if parts[0]
        acc = {term: parts[0]}
        addKey(acc, parts[1])
        addKey(acc, parts[2])
        console.log(acc)
        acc

  $get: ($http, $timeout)->
    prov = {
      active: 0
      notifications: []
      error: null
      metadata: (cb)->
        uri = '/metadata'
        http(method: 'GET', url: uri).success(cb)
      tags: (cb)->
        uri = '/_tags'
        http(method: 'GET', url: uri).success(cb)
      affixResourceTags: (rt, id, tags, cb)->
        uri = "/#{rt}/#{id}/_tags"
        http(method: 'POST', url: uri, headers: {"Category": buildTags(tags)}).success(cb)
      removeResourceTags: (rt, id, cb)->
        uri = "/#{rt}/#{id}/_tags/_delete"
        http(method: 'POST', url: uri).success(cb)
      profile: (rt, cb)->
        http(method: 'GET', url: "/Profile/#{rt}").success(cb)
      search: (rt, query, cb)->
        uri = "/#{rt}/_search"
        http(method: 'GET', url: uri, params: angular.copy(query)).success(cb)
      create: (rt, res, tags, cb)->
        uri = "/#{rt}"
        http(method: 'POST', url: uri, data: res, headers: {"Category": buildTags(tags)}).success(cb)
      validate: (rt, res, cb)->
        uri = "/#{rt}/_validate"
        http(method: 'POST', url: uri, data: res).success(cb)
      read: (rt, id, cb)->
        uri = "/#{rt}/#{id}"
        http(method: 'GET', url: uri).success (data, status, headers, config)->
          cb(headers('Content-Location'), data, extractTags(headers('Category')))
      update: (rt, id, cl, res, tags, cb)->
        uri = "/#{rt}/#{id}"
        http(method: "PUT", url: uri, data: res, headers: {'Content-Location': cl, "Category": buildTags(tags)}).success(cb)
      delete: (rt,id, cb)->
        uri = "/#{rt}/#{id}"
        http(method: "DELETE", url: uri).success(cb)
      history: (rt, id, cb)->
        uri = "/#{rt}/#{id}/_history"
        http(method: 'GET', url: uri).success(cb)
      removeNotification: (i)->
        prov.notifications.splice(prov.notifications.indexOf(i), 1)
    }

    http = (params)->
      note = angular.copy(params)
      prov.notifications.push(note)
      prov.active += 1
      $timeout (()-> prov.removeNotification(note)), NOTIFICATION_REMOVE_TIMEOUT
      params.params || = {}
      params.params._format = 'application/json'
      $http(params)
        .success (data, status, _, req)->
          prov.active -= 1
          note.status = status
        .error (vv, status, _, req)->
          prov.active -= 1
          note.status = status
          prov.error = vv || "Server error #{status} while loading:  #{params.url}"
    prov
