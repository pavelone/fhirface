NOTIFICATION_REMOVE_TIMEOUT = 2000
angular.module('fhirface').provider 'fhir', ()->
  $get: ($http, $timeout)->
    prov = {
      active: 0
      notifications: []
      error: null
      metadata: (cb)->
        uri = '/metadata'
        http(method: 'GET', url: uri).success(cb)
      profile: (rt, cb)->
        http(method: 'GET', url: "/Profile/#{rt}").success(cb)
      search: (rt, query, cb)->
        uri = "/#{rt}/_search"
        http(method: 'GET', url: uri, params: angular.copy(query)).success(cb)
      create: (rt, res, cb)->
        uri = "/#{rt}"
        http(method: 'POST', url: uri, data: res).success(cb)
      validate: (rt, res, cb)->
        uri = "/#{rt}/_validate"
        http(method: 'POST', url: uri, data: res).success(cb)
      read: (rt, id, cb)->
        uri = "/#{rt}/#{id}"
        http(method: 'GET', url: uri).success(cb)
      update: (rt, id, cl, res, cb)->
        uri = "/#{rt}/#{id}"
        http(method: "PUT", url: uri, data: res, headers: {'Content-Location': cl}).success(cb)
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
