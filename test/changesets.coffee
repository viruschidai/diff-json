expect = require 'expect.js'
changesets = require '../src/changesets'

describe 'changesets', ->

  describe 'diff()', ->
    oldObj = newObj = null

    before ->
      oldObj =
        name: 'joe'
        age: 55
        children: [
          {name: 'kid1', age: 1}
          {name: 'kid2', age: 2}
        ]

      newObj =
        name: 'smith'
        children: [
          {name: 'kid3', age: 3}
          {name: 'kid1', age: 0}
          {name: 'kid2', age: 2}
        ]

    it 'should return correct diff for object with embedded array object that does not have key specified', ->
      diffs = changesets.diff oldObj, newObj
      expect(diffs).to.eql [
        { type: 'deleted', key: [ 'age' ], value: 55 },
        { type: 'modified', key: [ 'name' ], value: 'smith', oldValue: 'joe' },
        { type: 'added', key: [ 'children', '$2' ], value: { name: 'kid2', age: 2 } },
        { type: 'modified', key: [ 'children', '$0', 'name' ], value: 'kid3', oldValue: 'kid1' },
        { type: 'modified', key: [ 'children', '$0', 'age' ], value: 3, oldValue: 1 },
        { type: 'modified', key: [ 'children', '$1', 'name' ], value: 'kid1', oldValue: 'kid2' },
        { type: 'modified', key: [ 'children', '$1', 'age' ], value: 0, oldValue: 2 }
      ]

    it 'should return correct diff for object with embedded array that has key specified', ->
      diffs = changesets.diff oldObj, newObj, {'children': 'name'}
      expect(diffs).to.eql [
        { type: 'deleted', key: [ 'age' ], value: 55 },
        { type: 'modified', key: [ 'name' ], value: 'smith', oldValue: 'joe' },
        { type: 'added', key: [ 'children', '$kid3' ], value: { name: 'kid3', age: 3 } },
        { type: 'modified', key: [ 'children', '$kid1', 'age' ], value: 0, oldValue: 1 }
      ]
