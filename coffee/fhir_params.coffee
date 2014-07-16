# this module to handle search params api
# http(method: 'GET', url: "/Profile/#{rt}").success(cb)
# query:
# { count: 100,
#   offset: 0,
#   sort: [{name: 'date', direction: 'asc'}, {name: 'id'}],
#   includes: ???
#   params: [{
#     name: 'name',
#     type: 'string',
#     modifier: 'exact',
#     operator: null,
#     values: [tp]
#   }]
# }
# tp = string, number, code&system, url
# type tp toParamString, isNull
tags = [
  {type: 'string',  name: '_tag', documentation: 'Search by tag'},
  {type: 'string',  name: '_profile', documentation: 'Search by profile tag'},
  {type: 'string',  name: '_security', documentation: 'Search by security tag'}
]

identity = (x)-> x
rm = (x, xs)-> xs.splice(xs.indexOf(x),1)
modifiers = {
  number:['','missing']
  string: ['',':missing', ':exact']
  reference: ['',':missing']
  token: ['',':missing', ':text']
  date: ['',':missing']
}
operations = {
  number:['=', '>', '>=', '<', '<=']
  date: ['=', '>', '>=', '<', '<=']
}

# create empty query object
class Query
  constructor: (profile)->
    @searchParam = profile.structure[0].searchParam
    @searchParam.unshift(t) for t in tags
    @searchChains = @searchParam.filter((x)-> x.type == 'reference')
    @searchIncludes = profile.structure[0]
      .differential.element.filter (x)->
        (x.definition.type && x.definition.type[0] && x.definition.type[0].code) == 'ResourceReference'

    @profile = profile

  count: 100,
  offset: 0,
  sort: [],
  includes: [],
  params: []
  addSortParam: (param)=>
    @sort.push({name: param.name, direction: 'asc'})

  removeSortParam: (param)=>
    rm(param, @sort)

  addInclude: (ref)=>
    @includes.push(ref) unless @includes.indexOf(ref) > -1

  removeInclude: (ref)=>
    rm(ref, @includes)

  toQueryString: ()=>
    @params.map(_mkSearchParam).filter(identity)
      .concat(@sort.map((i)-> "_sort:#{i.direction || 'asc'}=#{i.name}"))
      .concat(@includes.map((i)-> "_include=#{i.path}"))
      .join('&')

  addSearchParam: (param)=>
    @params.push(
      name: param.name,
      type: param.type,
      modifier: '',
      operations: operations[param.type] || ['='],
      modifiers:  modifiers[param.type] || [],
      operation: '=',
      values: [{}]
    )
    @params = @params.sort((a,b)-> a.name.localeCompare(b.name))

  removeSearchParam: (param)=>
    rm(param, @params)

  cloneSearchParam: (param)=>
    @addSearchParam({name: param.name, type: param.type})

  addParamValue: (param, {})=>
    param.values.push({})

  removeParamValue: (param, value)=>
    rm(value, param.values)

_mkSearchParam = (p)->
  switch p.type
    when 'string'    then _stringToQuery(p)
    when 'token'     then _tokenToQuery(p)
    when 'date'      then _dateToQuery(p)
    when 'number'    then _numberToQuery(p)
    when 'reference' then _referenceToQuery(p)
    else
      null

_stringToQuery = (p)->
  values = p.values.map((i)-> i.value).map($.trim).filter(identity)
  return null if values.length == 0
  "#{p.name}#{p.modifier}=#{values.join(',')}"

_referenceToQuery = (p)->
  values = p.values.map((i)-> i.value).map($.trim).filter(identity)
  return null if values.length == 0
  "#{p.name}#{p.modifier}=#{values.join(',')}"

_tokenToQuery= (p)->
  values = p.values
    .filter((i)-> $.trim(i.code))
    .map((i)-> [i.system, i.code].filter(identity).join('|'))
  return null if values.length == 0
  "#{p.name}#{p.modifier}=#{values.join(',')}"

_dateToQuery= (p)->
  values = p.values.map((i)-> i.value).map($.trim).filter(identity)
  return null if values.length == 0
  "#{p.name}=#{p.operation}#{values.join(',')}"

_numberToQuery= (p)->
  values = p.values.map((i)-> i.value).map($.trim).filter(identity)
  return null if values.length == 0
  "#{p.name}=#{p.operation}#{values.join(',')}"

angular.module('fhirface').factory 'fhirParams', ()-> ((profile)-> new Query(profile))
