expect = require 'expect.js'
changesets = require '../src/changesets'
{op} = changesets

describe 'changesets', ->
  oldObj = newObj = changeset = changesetWithouEmbeddedKey = null

  beforeEach ->
    oldObj =
      name: 'joe'
      age: 55
      coins: [2, 5]
      children: [
        {name: 'kid1', age: 1}
        {name: 'kid2', age: 2}
      ]

    newObj =
      name: 'smith'
      coins: [2, 5, 1]
      children: [
        {name: 'kid3', age: 3}
        {name: 'kid1', age: 0}
        {name: 'kid2', age: 2}
      ]

    changeset = [
      {type: op.MODIFIED, key: [ 'name' ], value: 'smith', oldValue: 'joe'}
      {type: op.ADDED, key: [ 'coins', 2 ], value: 1}
      {type: op.MODIFIED, key: [ 'children', '$name=kid1', 'age' ], value: 0, oldValue: 1}
      {type: op.ADDED, key: [ 'children', '$name=kid3' ], value: {name: 'kid3', age: 3}}
      {type: op.DELETED, key: [ 'age' ], value: 55}
    ]

    changesetWithouEmbeddedKey = [
      {type: op.MODIFIED, key: [ 'name' ], value: 'smith', oldValue: 'joe'}
      {type: op.ADDED, key: [ 'coins', 2 ], value: 1}
      {type: op.MODIFIED, key: [ 'children', 0, 'name' ], value: 'kid3', oldValue: 'kid1'}
      {type: op.MODIFIED, key: [ 'children', 0, 'age' ], value: 3, oldValue: 1}
      {type: op.MODIFIED, key: [ 'children', 1, 'name' ], value: 'kid1', oldValue: 'kid2'}
      {type: op.MODIFIED, key: [ 'children', 1, 'age' ], value: 0, oldValue: 2}
      {type: op.ADDED, key: [ 'children', 2 ], value: {name: 'kid2', age: 2}}
      {type: op.DELETED, key: [ 'age' ], value: 55}
    ]


  describe 'diff()', ->

    it 'should return correct diff for object with embedded array object that does not have key specified', ->
      diffs = changesets.diff oldObj, newObj
      expect(diffs).to.eql changesetWithouEmbeddedKey

    it 'should return correct diff for object with embedded array that has key specified', ->
      diffs = changesets.diff oldObj, newObj, {'children': 'name'}
      expect(diffs).to.eql changeset


  describe 'applyChange()', ->

    it 'should transfer oldObj to newObj with changeset', ->
      changesets.applyChange oldObj, changeset
      newObj.children.sort (a, b) -> a.name > b.name
      expect(oldObj).to.eql newObj

    it 'should transfer oldObj to newObj with changesetWithouEmbeddedKey', ->
      changesets.applyChange oldObj, changesetWithouEmbeddedKey
      newObj.children.sort (a, b) -> a.name > b.name
      oldObj.children.sort (a, b) -> a.name > b.name
      expect(oldObj).to.eql newObj


  describe 'revert()', ->

    it 'should transfer newObj to oldObj with changeset', ->
      changesets.revertChange newObj, changeset
      oldObj.children.sort (a, b) -> a.name > b.name
      newObj.children.sort (a, b) -> a.name > b.name
      expect(newObj).to.eql oldObj


    it 'should transfer newObj to oldObj with changesetWithouEmbeddedKey', ->
      changesets.revertChange newObj, changesetWithouEmbeddedKey
      oldObj.children.sort (a, b) -> a.name > b.name
      newObj.children.sort (a, b) -> a.name > b.name
      expect(newObj).to.eql oldObj
