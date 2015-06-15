expect = require 'expect.js'
util = require 'util'
changesets = require '../src/changesets'
{op} = changesets

describe 'changesets', ->
  oldObj = newObj = changeset = changesetWithouEmbeddedKey = null

  beforeEach ->
    oldObj =
      name: 'joe'
      age: 55
      mixed: 10
      nested: inner: 1
      empty: undefined
      date: new Date 'October 13, 2014 11:13:00'
      coins: [2, 5]
      toys: ['car', 'doll', 'car']
      pets: [undefined, null]
      children: [
        {name: 'kid1', age: 1, subset: [
          {id: 1, value: 'haha'}
          {id: 2, value: 'hehe'}
        ]}
        {name: 'kid2', age: 2}
      ]


    newObj =
      name: 'smith'
      mixed: '10'
      nested: inner: 2
      date: new Date 'October 13, 2014 11:13:00'
      coins: [2, 5, 1]
      toys: []
      pets: []
      children: [
        {name: 'kid3', age: 3}
        {name: 'kid1', age: 0, subset: [
          {id: 1, value: 'heihei'}
        ]}
        {name: 'kid2', age: 2}
      ]


  changeset = [
    { type: 'update', key: 'name', value: 'smith', oldValue: 'joe' }
    { type: 'remove', key: 'mixed', value: 10 }
    { type: 'add', key: 'mixed', value: '10' }
    { type: 'update', key: 'nested', changes: [
        { type: 'update', key: 'inner', value: 2, oldValue: 1}
      ]
    }
    { type: 'update', key: 'coins', embededKey: '$index', changes: [{ type: 'add', key: '2', value: 1 } ] }
    { type: 'update', key: 'toys', embededKey: '$index', changes: [
        { type: 'remove', key: '0', value: 'car' }
        { type: 'remove', key: '1', value: 'doll' }
        { type: 'remove', key: '2', value: 'car' }
      ] 
    }
    { type: 'update', key: 'pets', embededKey: '$index', changes: [
        { type: 'remove', key: '0', value: undefined }
        { type: 'remove', key: '1', value: null }
      ]
    }
    { type: 'update', key: 'children', embededKey: 'name', changes: [
        { type: 'update', key: 'kid1', changes: [
          { type: 'update', key: 'age', value: 0, oldValue: 1 }
          { type: 'update', key: 'subset', embededKey: 'id', changes: [
              { type: 'update', key: 1, changes: [{ type: 'update', key: 'value', value: 'heihei', oldValue: 'haha' } ] }
              { type: 'remove', key: 2, value: {id: 2, value: 'hehe'} }
            ]
          }
        ]}
        { type: 'add', key: 'kid3', value: { name: 'kid3', age: 3 } }
      ]
    }

    { type: 'remove', key: 'age', value: 55 }
    { type: 'remove', key: 'empty', value: undefined }
  ]

  changesetWithoutEmbeddedKey = [
    { type: 'update', key: 'name', value: 'smith', oldValue: 'joe' }
    { type: 'remove', key: 'mixed', value: 10 }
    { type: 'add', key: 'mixed', value: '10' }
    { type: 'update', key: 'nested', changes: [
        { type: 'update', key: 'inner', value: 2, oldValue: 1}
      ]
    }
    { type: 'update', key: 'coins', embededKey: '$index', changes: [ { type: 'add', key: '2', value: 1 } ] }
    { type: 'update', key: 'toys', embededKey: '$index', changes: [
        { type: 'remove', key: '0', value: 'car' }
        { type: 'remove', key: '1', value: 'doll' }
        { type: 'remove', key: '2', value: 'car' }
      ]
    }
    { type: 'update', key: 'pets', embededKey: '$index', changes: [
        { type: 'remove', key: '0', value: undefined }
        { type: 'remove', key: '1', value: null }
      ]
    }
    { type: 'update', key: 'children', embededKey: '$index', changes: [
          {
            type: 'update', key: '0', changes: [
              { type: 'update', key: 'name', value: 'kid3', oldValue: 'kid1' }
              { type: 'update', key: 'age', value: 3, oldValue: 1 }
              { type: 'remove', key: 'subset', value: [ { id: 1, value: 'haha' }, { id: 2, value: 'hehe' } ]}
            ]
          }
          {
            type: 'update', key: '1', changes: [
               { type: 'update', key: 'name', value: 'kid1', oldValue: 'kid2' }
               { type: 'update', key: 'age', value: 0, oldValue: 2 }
               { type: 'add', key: 'subset', value: [ { id: 1, value: 'heihei' } ] }
            ]
          },
          { type: 'add', key: '2', value: { name: 'kid2', age: 2 } }
        ]
    }

    { type: 'remove', key: 'age', value: 55 }
    { type: 'remove', key: 'empty', value: undefined }
  ]


  describe 'diff()', ->

    it 'should return correct diff for object with embedded array object that does not have key specified', ->
      diffs = changesets.diff oldObj, newObj
      expect(diffs).to.eql changesetWithoutEmbeddedKey

    it 'should return correct diff for object with embedded array that has key specified', ->
      diffs = changesets.diff oldObj, newObj, {'children': 'name', 'children.subset': 'id'}
      expect(diffs).to.eql changeset


  describe 'applyChanges()', ->

    it 'should transfer oldObj to newObj with changeset', ->
      changesets.applyChanges oldObj, changeset
      newObj.children.sort (a, b) -> a.name > b.name
      expect(oldObj).to.eql newObj

    it 'should transfer oldObj to newObj with changesetWithoutEmbeddedKey', ->
      changesets.applyChanges oldObj, changesetWithoutEmbeddedKey
      newObj.children.sort (a, b) -> a.name > b.name
      oldObj.children.sort (a, b) -> a.name > b.name
      expect(oldObj).to.eql newObj


  describe 'revertChanges()', ->

    it 'should transfer newObj to oldObj with changeset', ->
      changesets.revertChanges newObj, changeset
      oldObj.children.sort (a, b) -> a.name > b.name
      newObj.children.sort (a, b) -> a.name > b.name
      expect(newObj).to.eql oldObj


    it 'should transfer newObj to oldObj with changesetWithoutEmbeddedKey', ->
      changesets.revertChanges newObj, changesetWithoutEmbeddedKey
      oldObj.children.sort (a, b) -> a.name > b.name
      newObj.children.sort (a, b) -> a.name > b.name
      expect(newObj).to.eql oldObj
