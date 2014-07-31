_ = require 'underscore'

exports.op =
  DELETED: '-'
  ADDED: '+'
  MODIFIED: '+-'


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
    changes.push type: exports.op.DELETED, key: path, value: oldObj
    changes.push type: exports.op.ADDED, key: path, value: newObj

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

  intersectionKeys = _.intersection oldObjKeys, newObjKeys
  for k in intersectionKeys
    newPath = path.concat [k]
    changes = changes.concat compare oldObj[k], newObj[k], newPath, embededObjKeys

  addedKeys = _.difference newObjKeys, oldObjKeys
  for k in addedKeys
    newPath = path.concat [k]
    changes.push type: exports.op.ADDED, key: newPath, value: newObj[k]

  deletedKeys = _.difference oldObjKeys, newObjKeys
  for k in deletedKeys
    newPath = path.concat [k]
    changes.push type: exports.op.DELETED, key: newPath, value: oldObj[k]

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
      obj["$#{uniqKey}=#{key}"] = value
  else
    for index, value of arr then obj[index] = value
  return obj


comparePrimitives = (oldObj, newObj, path) ->
  changes = []
  if oldObj isnt newObj
    changes.push type: exports.op.MODIFIED, key: path, value: newObj, oldValue: oldObj
  return changes


applyChange = (obj, change) ->
  keys = change.key
  ptr = obj
  for index, key of keys
    if +index is (keys.length - 1)
      switch change.type
        when exports.op.ADDED
          addKeyValue ptr, key, change.value
        when exports.op.MODIFIED
          modifyKeyValue ptr, key, change.value
        when exports.op.DELETED
          removeKey ptr, key
    else
      ptr = getNextPtr ptr, key
  return obj


isEmbeddedKey = (key) -> /\$.*=/gi.test key


removeKey = (obj, key) ->
  if Array.isArray obj
    if isEmbeddedKey key
      {uniqKey, value} = parseEmbeddedKeyValue key
      index = indexOfItemInArray obj, uniqKey, value
    obj.splice key, 1
  else
    delete obj[key]


indexOfItemInArray = (arr, key, value) ->
  for index, item of arr
    if item[key] is value then return index

  return -1


modifyKeyValue = (obj, key, value) -> obj[key] = value


addKeyValue = (obj, key, value) ->
  if Array.isArray obj then obj.push value else obj[key] = value


getNextPtr = (obj, key) ->
  if Array.isArray(obj) and isEmbeddedKey(key)
    {uniqKey, value} = parseEmbeddedKeyValue key
    return _.find obj, (item) -> item[uniqKey] is value
  return obj[key]


parseEmbeddedKeyValue = (key) ->
  uniqKey = key.substring 1, key.indexOf '='
  value = key.substring key.indexOf('=') + 1
  return {uniqKey, value}


revertChange = (obj, change) ->
  keys = change.key
  ptr = obj
  for index, key of keys
    if +index is (keys.length - 1)
      switch change.type
        when exports.op.ADDED
          removeKey ptr, key
        when exports.op.MODIFIED
          modifyKeyValue ptr, key, change.oldValue
        when exports.op.DELETED
          addKeyValue ptr, key, change.value
    else
      ptr = getNextPtr ptr, key

  return obj


exports.diff = (oldObj, newObj, embededObjKeys) ->
  return compare oldObj, newObj, [], embededObjKeys


exports.applyChange = (obj, changeset) ->
  for change in changeset
    applyChange obj, change


exports.revertChange = (obj, changeset) ->
  for change in changeset
    revertChange obj, change
