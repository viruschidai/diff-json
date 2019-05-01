(->

  changeset =
    VERSION: '0.1.4'

  if typeof module is 'object' and module.exports
    _intersection = require 'lodash.intersection'
    _difference = require 'lodash.difference'
    _keyBy = require 'lodash.keyby'
    _find = require 'lodash.find'
    module.exports = exports = changeset
  else
    # just set the global for non-node platforms.
    this.changeset = changeset


  getTypeOfObj = (obj) ->
    if typeof obj is 'undefined'
      return 'undefined'

    if obj is null
      return null

    return Object.prototype.toString.call(obj) .match(/^\[object\s(.*)\]$/)[1];


  getKey = (path) ->
    path[path.length - 1] ? '$root'


  compare = (oldObj, newObj, path, embededObjKeys, keyPath) ->
    changes = []

    typeOfOldObj = getTypeOfObj oldObj
    typeOfNewObj = getTypeOfObj newObj

    # if type of object changes, consider it as old obj has been deleted and a new object has been added
    if typeOfOldObj != typeOfNewObj
      changes.push type: changeset.op.REMOVE, key: getKey(path), value: oldObj
      changes.push type: changeset.op.ADD, key: getKey(path), value: newObj
      return changes

    switch typeOfOldObj
      when 'Date'
        changes = changes.concat comparePrimitives oldObj.getTime(), newObj.getTime(), path
      when 'Object'
        diffs = compareObject oldObj, newObj, path, embededObjKeys, keyPath
        if diffs.length
          if path.length
            changes.push type: changeset.op.UPDATE, key: getKey(path), changes: diffs
          else
            changes = changes.concat diffs
      when 'Array'
        changes = changes.concat compareArray oldObj, newObj, path, embededObjKeys, keyPath
      when 'Function'
        # do nothing
      else
        changes = changes.concat comparePrimitives oldObj, newObj, path

    return changes


  compareObject = (oldObj, newObj, path, embededObjKeys, keyPath, skipPath = false) ->
    changes = []

    oldObjKeys = Object.keys(oldObj)
    newObjKeys = Object.keys(newObj)

    intersectionKeys = _intersection oldObjKeys, newObjKeys
    for k in intersectionKeys
      newPath = path.concat [k]
      newKeyPath = if skipPath then keyPath else keyPath.concat [k]
      diffs = compare oldObj[k], newObj[k], newPath, embededObjKeys, newKeyPath
      if diffs.length
        changes = changes.concat diffs

    addedKeys = _difference newObjKeys, oldObjKeys
    for k in addedKeys
      newPath = path.concat [k]
      newKeyPath = if skipPath then keyPath else keyPath.concat [k]
      changes.push type: changeset.op.ADD, key: getKey(newPath), value: newObj[k]

    deletedKeys = _difference oldObjKeys, newObjKeys
    for k in deletedKeys
      newPath = path.concat [k]
      newKeyPath = if skipPath then keyPath else keyPath.concat [k]
      changes.push type: changeset.op.REMOVE, key: getKey(newPath), value: oldObj[k]
    return changes


  compareArray = (oldObj, newObj, path, embededObjKeys, keyPath) ->
    uniqKey = embededObjKeys?[keyPath.join '.'] ? '$index'
    indexedOldObj = convertArrayToObj oldObj, uniqKey
    indexedNewObj = convertArrayToObj newObj, uniqKey
    diffs = compareObject indexedOldObj, indexedNewObj, path, embededObjKeys, keyPath, true
    return if diffs.length then [type: changeset.op.UPDATE, key: getKey(path), embededKey: uniqKey, changes: diffs] else []


  convertArrayToObj = (arr, uniqKey) ->
    obj = {}
    if uniqKey isnt '$index'
      obj = _keyBy arr, uniqKey
    else
      for index, value of arr then obj[index] = value
    return obj


  comparePrimitives = (oldObj, newObj, path) ->
    changes = []
    if oldObj isnt newObj
      changes.push type: changeset.op.UPDATE, key: getKey(path), value: newObj, oldValue: oldObj
    return changes


  isEmbeddedKey = (key) -> /\$.*=/gi.test key


  removeKey = (obj, key, embededKey) ->
    if Array.isArray obj
      if embededKey isnt '$index' or !obj[key]
        index = indexOfItemInArray obj, embededKey, key
      obj.splice index ? key, 1
    else
      delete obj[key]


  indexOfItemInArray = (arr, key, value) ->
    for index, item of arr
      if key is '$index'
        if item is value then return index
      else if item[key] is value then return index

    return -1


  modifyKeyValue = (obj, key, value) -> obj[key] = value


  addKeyValue = (obj, key, value) ->
    if Array.isArray obj then obj.push value else obj[key] = value


  parseEmbeddedKeyValue = (key) ->
    uniqKey = key.substring 1, key.indexOf '='
    value = key.substring key.indexOf('=') + 1
    return {uniqKey, value}


  applyLeafChange = (obj, change, embededKey) ->
    {type, key, value} = change
    switch type
      when changeset.op.ADD
        addKeyValue obj, key, value
      when changeset.op.UPDATE
        modifyKeyValue obj, key, value
      when changeset.op.REMOVE
        removeKey obj, key, embededKey


  applyArrayChange = (arr, change) ->
    for subchange in change.changes
      if subchange.value? or subchange.type is changeset.op.REMOVE
        applyLeafChange arr, subchange, change.embededKey
      else
        if change.embededKey is '$index'
          element = arr[+subchange.key]
        else
          element = _find arr, (el) -> el[change.embededKey] is subchange.key
        changeset.applyChanges element, subchange.changes


  applyBranchChange = (obj, change) ->
    if Array.isArray obj
      applyArrayChange obj, change
    else
      changeset.applyChanges obj, change.changes


  revertLeafChange = (obj, change, embededKey) ->
    {type, key, value, oldValue} = change
    switch type
      when changeset.op.ADD
        removeKey obj, key, embededKey
      when changeset.op.UPDATE
        modifyKeyValue obj, key, oldValue
      when changeset.op.REMOVE
        addKeyValue obj, key, value


  revertArrayChange = (arr, change) ->
    for subchange in change.changes
      if subchange.value? or subchange.type is changeset.op.REMOVE
        revertLeafChange arr, subchange, change.embededKey
      else
        if change.embededKey is '$index'
          element = arr[+subchange.key]
        else
          element = _find arr, (el) -> el[change.embededKey] is subchange.key
        changeset.revertChanges element, subchange.changes


  revertBranchChange = (obj, change) ->
    if Array.isArray obj
      revertArrayChange obj, change
    else
      changeset.revertChanges obj, change.changes


  changeset.diff = (oldObj, newObj, embededObjKeys) ->
    return compare oldObj, newObj, [], embededObjKeys, []


  changeset.applyChanges = (obj, changesets) ->
    for change in changesets
      if change.value? or change.type is changeset.op.REMOVE
        applyLeafChange obj, change, change.embededKey
      else
        applyBranchChange obj[change.key], change


  changeset.revertChanges = (obj, changeset) ->
    for change in changeset.reverse()
      if !change.changes
        revertLeafChange obj, change
      else
        revertBranchChange obj[change.key], change


  changeset.op =
    REMOVE: 'remove'
    ADD: 'add'
    UPDATE: 'update'

  return
)()
