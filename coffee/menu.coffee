cropUuid = (id)->
  return "ups no uuid :(" unless id
  sid = id.substring(id.length - 6, id.length)
  "...#{sid}"

MENU=
  conformance: (p)-> {url: '/conformance', label: 'Conformance'}
  index:       (p)-> {url: "/resources/#{p.resourceType}", label: p.resourceType}
  show:        (p)-> {url: "/resources/#{p.resourceType}/#{p.id}", label: cropUuid(p.id)}
  history:     (p)-> {url: "/resources/#{p.resourceType}/#{p.id}/history", label: 'History', icon: 'fa-history'}
  new:         (p)-> {url: "/resources/#{p.resourceType}/new", label: "New", icon: "fa-plus"}

angular.module('fhirface').provider 'menu', ()->
  $get: ()->
    menu =
      items: []
      build: (p, items...)=>
        menu.items = items.map (i)->
          if i.match(/\*$/)
            menu.current = angular.extend({active: true}, MENU[i.replace(/\*$/,'')](p))
          else
            MENU[i](p)
    menu

