(->

  changeset =
    VERSION: '0.1.2'

  if typeof module is 'object' and module.exports
    _ = require 'lodash'
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


  compare = (oldObj, newObj, path, embededObjKeys) ->
    changes = []

    typeOfOldObj = getTypeOfObj oldObj
    typeOfNewObj = getTypeOfObj newObj

    # if type of object changes, consider it as old obj has been deleted and a new object has been added
    if typeOfOldObj != typeOfNewObj
      changes.push type: changeset.op.REMOVE, key: key: getKey(path), value: oldObj
      changes.push type: changeset.op.ADD, key: getKey(path), value: newObj

    switch typeOfOldObj
      when 'Object'
        diffs = compareObject oldObj, newObj, path, embededObjKeys
        if diffs.length
          if path.length
            changes.push type: changeset.op.UPDATE, key: getKey(path), changes: diffs
          else
            changes = changes.concat diffs
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
      diffs = compare oldObj[k], newObj[k], newPath, embededObjKeys
      if diffs.length
        changes = changes.concat diffs

    addedKeys = _.difference newObjKeys, oldObjKeys
    for k in addedKeys
      newPath = path.concat [k]
      changes.push type: changeset.op.ADD, key: getKey(newPath), value: newObj[k]

    deletedKeys = _.difference oldObjKeys, newObjKeys
    for k in deletedKeys
      newPath = path.concat [k]
      changes.push type: changeset.op.REMOVE, key: getKey(newPath), value: oldObj[k]
    return changes


  compareArray = (oldObj, newObj, path, embededObjKeys) ->
    uniqKey = embededObjKeys?[path.join '.'] ? '$index'
    indexedOldObj = convertArrayToObj oldObj, uniqKey
    indexedNewObj = convertArrayToObj newObj, uniqKey
    diffs = compareObject indexedOldObj, indexedNewObj, path, embededObjKeys
    return if diffs.length then [type: changeset.op.UPDATE, key: getKey(path), embededKey: uniqKey, changes: diffs] else []


  convertArrayToObj = (arr, uniqKey) ->
    obj = {}
    if uniqKey isnt '$index'
      obj = _.indexBy arr, uniqKey
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
      if embededKey isnt '$index'
        index = indexOfItemInArray obj, embededKey, key
      obj.splice index ? key, 1
    else
      delete obj[key]


  indexOfItemInArray = (arr, key, value) ->
    for index, item of arr
      if item[key] is value then return index

    return -1


  modifyKeyValue = (obj, key, value) -> obj[key] = value


  addKeyValue = (obj, key, value) ->
    if Array.isArray obj then obj.push value else obj[key] = value


  parseEmbeddedKeyValue = (key) ->
    uniqKey = key.substring 1, key.indexOf '='
    value = key.substring key.indexOf('=') + 1
    return {uniqKey, value}


  applyLeafChange = (obj, change) ->
    {type, key, value} = change
    switch type
      when changeset.op.ADD
        addKeyValue obj, key, value
      when changeset.op.UPDATE
        modifyKeyValue obj, key, value
      when changeset.op.REMOVE
        removeKey obj, key, change.embededKey


  applyArrayChange = (arr, change) ->
    for subchange in change.changes
      if subchange.value?
        applyLeafChange arr, subchange, change.embededKey
      else
        if change.embededKey is '$index'
          element = arr[+subchange.key]
        else
          element = _.find arr, (el) -> el[change.embededKey] is subchange.key
        changeset.applyChanges element, subchange.changes


  applyBranchChange = (obj, change) ->
    if Array.isArray obj
      applyArrayChange obj, change
    else
      changeset.applyChanges obj[change.key], change.changes


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
      if subchange.value?
        revertLeafChange arr, subchange, change.embededKey
      else
        if change.embededKey is '$index'
          element = arr[+subchange.key]
        else
          element = _.find arr, (el) -> el[change.embededKey] is subchange.key
        changeset.revertChanges element, subchange.changes


  revertBranchChange = (obj, change) ->
    if Array.isArray obj
      revertArrayChange obj, change
    else
      changeset.revertChanges obj[change.key], change.changes


  changeset.op =
      REMOVE: 'remove'
      ADD: 'add'
      UPDATE: 'update'


  changeset.diff = (oldObj, newObj, embededObjKeys) ->
      return compare oldObj, newObj, [], embededObjKeys


  changeset.applyChanges = (obj, changeset) ->
      for change in changeset
        if change.value?
          applyLeafChange obj, change
        else
          applyBranchChange obj[change.key], change


  changeset.revertChanges = (obj, changeset) ->
      for change in changeset
        if change.value?
          revertLeafChange obj, change
        else
          revertBranchChange obj[change.key], change
)()
