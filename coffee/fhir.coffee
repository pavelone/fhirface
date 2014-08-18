NOTIFICATION_REMOVE_TIMEOUT = 2000

BASE_PREFIX = '/' # if u have base FHIR url like http://one.com/two set BASE_PREFIX to "/two"
# BASE_PREFIX = 'http://try-fhirplace.hospital-systems.com/' # if u have base FHIR url like http://one.com/two set BASE_PREFIX to "/two"

angular.module('fhirface').provider 'fhir', ()->
  buildTags = (tags)->
    tags.filter((i)-> $.trim(i.term))
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
        acc

  $get: ($http, $timeout)->
    prov = {
      active: 0
      notifications: []
      error: null
      metadata: (cb)->
        uri = "#{BASE_PREFIX}metadata"
        http(method: 'GET', url: uri).success(cb)
      tags_all: (cb)->
        uri = "#{BASE_PREFIX}_tags"
        http(method: 'GET', url: uri).success(cb)
      tags_type: (rt, cb)->
        uri = "#{BASE_PREFIX}#{rt}/_tags"
        http(method: 'GET', url: uri).success(cb)
      tags: (rt, id, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}/_tags"
        http(method: 'GET', url: uri).success(cb)
      tags_version: (rt, id, vid, b)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}/_history/#{vid}/_tags"
        http(method: 'GET', url: uri).success(cb)
      affixResourceTags: (rt, id, tags, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}/_tags"
        headers = {}
        tagHeader = buildTags(tags)
        if tagHeader
          headers["Category"] =  tagHeader
          http(method: 'POST', url: uri, headers: headers).success(cb)
        else
          console.log('Empty tags')
      removeResourceTags: (rt, id, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}/_tags/_delete"
        http(method: 'POST', url: uri).success(cb)
      profile: (rt, cb)->
        # TODO: use conformance href
        http(method: 'GET', url: "/Profile/#{rt}").success(cb)
      # query should be instance of fhirParam
      search: (rt, query, cb)->
        uri = "#{BASE_PREFIX}#{rt}/_search?#{query.toQueryString()}"
        http(method: 'GET', url: uri).success(cb)
      create: (rt, res, tags, cb)->
        uri = "#{BASE_PREFIX}#{rt}"
        headers = {}
        tagHeader = buildTags(tags)
        headers["Category"] =  tagHeader if tagHeader
        http(method: 'POST', url: uri, data: res, headers: headers).success(cb)
      validate: (rt, id, cl, res, cb)->
        uri = "#{BASE_PREFIX}#{rt}/_validate"
        if id
          uri = uri + '/' + id
        headers = {}
        tagHeader = buildTags(tags)
        headers["Category"] =  tagHeader if tagHeader
        headers['Content-Location'] = cl
        http(method: 'POST', url: uri, data: res, headers: headers).success(cb)
      read: (rt, id, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}"
        http(method: 'GET', url: uri).success (data, status, headers, config)->
          cb(headers('Content-Location'), data, extractTags(headers('Category')))
      update: (rt, id, cl, res, tags, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}"
        headers = {}
        tagHeader = buildTags(tags)
        headers["Category"] =  tagHeader if tagHeader
        headers['Content-Location'] = cl
        http(method: "PUT", url: uri, data: res, headers: headers).success(cb)
      delete: (rt,id, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}"
        http(method: "DELETE", url: uri).success(cb)
      history: (rt, id, cb)->
        uri = "#{BASE_PREFIX}#{rt}/#{id}/_history"
        http(method: 'GET', url: uri).success(cb)
      history_type: (rt, cb)->
        uri = "#{BASE_PREFIX}#{rt}/_history"
        http(method: 'GET', url: uri).success(cb)
      history_all: (cb)->
        uri = "#{BASE_PREFIX}_history"
        http(method: 'GET', url: uri).success(cb)
      removeNotification: (i)->
        prov.notifications.splice(prov.notifications.indexOf(i), 1)
      transaction: (bundle, cb)->
        uri = "#{BASE_PREFIX}"
        http(method: 'POST', url: uri, data: bundle).success(cb)
      document: (bundle, cb)->
        uri = "#{BASE_PREFIX}/Document"
        http(method: 'POST', url: uri, data: bundle).success(cb)
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
