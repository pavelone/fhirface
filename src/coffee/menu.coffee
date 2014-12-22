cropUuid = (id)->
  return "ups no uuid :(" unless id
  sid = id.substring(id.length - 6, id.length)
  "...#{sid}"

MENU=
  authorization: (p)-> {url: '/authorization', label: 'Authorization'}
  conformance:  (p)-> {url: '/conformance', label: 'Conformance'}
  index_all:    (p)-> {url: "/resources/Any", label: 'Any'}
  history_all:  (p)-> {url: "/resources/Any/history", label: 'History', icon: 'fa-history'}
  tags_all:     (p)-> {url: "/resources/Any/tags", label: 'Tags', icon: 'fa-tags'}
  transaction:  (p)-> {url: "/resources/Any/transaction", label: 'Transaction', icon: 'fa-th-list'}
  document:     (p)-> {url: "/resources/Any/document", label: 'Document', icon: 'fa-book'}
  index:        (p)-> {url: "/resources/#{p.resourceType}", label: p.resourceType}
  history_type: (p)-> {url: "/resources/#{p.resourceType}/history", label: 'History', icon: 'fa-history'}
  tags_type:    (p)-> {url: "/resources/#{p.resourceType}/tags", label: 'Tags', icon: 'fa-tags'}
  show:         (p)-> {url: "/resources/#{p.resourceType}/#{p.id}", label: cropUuid(p.id)}
  history:      (p)-> {url: "/resources/#{p.resourceType}/#{p.id}/history", label: 'History', icon: 'fa-history'}
  tags:         (p)-> {url: "/resources/#{p.resourceType}/#{p.id}/tags", label: 'Tags', icon: 'fa-tags'}
  new:          (p)-> {url: "/resources/#{p.resourceType}/new", label: "New", icon: "fa-plus"}

angular.module('fhirface').provider 'menu', ()->
  $get: ()->
    menu =
      items: []
      build: (p, items...)=>
        state = 'path'
        menu.items = items.map (i)->
          if i.match(/\*$/)
            state = 'end'
            menu.current = angular.extend({active: true}, MENU[i.replace(/\*$/,'')](p))
          else if state == 'guess'
            angular.extend({guess: true}, MENU[i](p))
          else
            if state == 'end'
              state = 'guess'
            MENU[i](p)
    menu

