_ = require 'underscore'

op =
  DELETED: 'deleted'
  ADDED: 'added'
  MODIFIED: 'modified'


getTypeOfObj = (obj) ->
  if typeof obj is 'undefined'
    return 'undefined'

  if obj is null
    return null

  return Object.prototype.toString.call(obj) .match(/^\[object\s(.*)\]$/)[1];


compare = (oldObj, newObj, path, embededObjKeys) ->
  changes = []

  typeOfOldObj = getTypeOfObj oldObj
  typeOfNewObj = getTypeOfObj newObj

  # if type of object changes, consider it as old obj has been deleted and a new object has been added
  if typeOfOldObj != typeOfNewObj
    changes.push type: op.DELETED, key: path, value: oldObj
    changes.push type: op.ADDED, key: path, value: newObj

  switch typeOfOldObj
    when 'Object'
      changes = changes.concat compareObject oldObj, newObj, path, embededObjKeys
    when 'Array'
      changes = changes.concat compareArray oldObj, newObj, path, embededObjKeys
    when 'Function'
      # do nothing
    else
      changes = changes.concat comparePrimitives oldObj, newObj, path

  return changes


compareObject = (oldObj, newObj, path, embededObjKeys) ->
  changes = []

  oldObjKeys = Object.keys(oldObj)
  newObjKeys = Object.keys(newObj)

  addedKeys = _.difference newObjKeys, oldObjKeys
  for k in addedKeys
    newPath = path.concat [k]
    changes.push type: op.ADDED, key: newPath, value: newObj[k]

  deletedKeys = _.difference oldObjKeys, newObjKeys
  for k in deletedKeys
    newPath = path.concat [k]
    changes.push type: op.DELETED, key: newPath, value: oldObj[k]

  intersectionKeys = _.intersection oldObjKeys, newObjKeys
  for k in intersectionKeys
    newPath = path.concat [k]
    changes = changes.concat compare oldObj[k], newObj[k], newPath, embededObjKeys

  return changes


compareArray = (oldObj, newObj, path, embededObjKeys) ->
  uniqKey = embededObjKeys?[path.join '.']
  indexedOldObj = convertArrayToObj oldObj, uniqKey
  indexedNewObj = convertArrayToObj newObj, uniqKey
  changes = compareObject indexedOldObj, indexedNewObj, path, embededObjKeys


convertArrayToObj = (arr, uniqKey) ->
  obj = {}
  if uniqKey
    for value in arr
      key = value[uniqKey]
      obj["$#{key}"] = value
  else
    for index, value of arr then obj["$#{index}"] = value
  return obj


comparePrimitives = (oldObj, newObj, path) ->
  changes = []
  if oldObj isnt newObj
    changes.push type: op.MODIFIED, key: path, value: newObj, oldValue: oldObj
  return changes


module.exports = exports =
  diff: (oldObj, newObj, embededObjKeys) ->
    return compare oldObj, newObj, [], embededObjKeys


  apply: ->


  revert: ->
