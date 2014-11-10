# this module to handle search params api
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

collectChains = (profile)->
  searchParam = profile.structure[0].searchParam
  elemsIdx = profile.structure[0].differential
    .element.reduce(((idx, x)-> idx[x.path]=x; idx ),{})

  # console.log(elemsIdx)

  searchParam.reduce(((acc, x)->
    return acc unless x.type == 'reference'
    path = x.xpath.replace(/f:/g,'').replace(/\//g,'.')
    elem = elemsIdx[path]
    return acc unless elem
    for t in elem.definition.type
      acc.push({sp: x, tp: t})
    acc
  ), [])

collectChainType = (profile)->
  searchParam = profile.structure[0].searchParam
  elemsIdx = profile.structure[0].differential
    .element.reduce(((idx, x)-> idx[x.path]=x; idx ),{})

  # console.log(elemsIdx)

  types = {}

  searchParam.reduce(((acc, x)->
    return acc unless x.type == 'reference'
    path = x.xpath.replace(/f:/g,'').replace(/\//g,'.')
    elem = elemsIdx[path]
    return acc unless elem
    for t in elem.definition.type
      acc.push({sp: x, tp: t})
      if t.profile
        tp = t.profile.split("/")
        rt = tp[tp.length - 1]
        if rt != 'Any'
          (types[x.name] ||= []).push(rt)
    acc
  ), [])
  types

# create empty query object
class Query
  constructor: (profile)->
    @searchParam = profile.structure[0].searchParam
    @searchParam.unshift(t) for t in tags
    @searchChains = collectChains(profile)
    @chainType = collectChainType(profile)

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

angular.module('ng-fhir').factory '$fhirParams', ()-> ((profile)-> new Query(profile))
