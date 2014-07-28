# changesets

A changesets tool for javascript objects inspired by https://github.com/eugeneware/changeset.

## Features

### Generate diff between different versions of an object.

If a key is specified for an embedded array, the diff will be generated based on the objects have same keys.

#### Examples:

```javascript

  var changesets = require('./index');
  var newObj, oldObj;

  oldObj = {
    name: 'joe',
    age: 55,
    coins: [2, 5],
    children: [
      {name: 'kid1', age: 1 },
      {name: 'kid2', age: 2 }
    ]};

  newObj = {
    name: 'smith',
    coins: [2, 5, 1],
    children: [
      {name: 'kid3', age: 3 },
      {name: 'kid1', age: 0 },
      {name: 'kid2', age: 2 }
    ]};


  # Assume children is an array of child object and the child object has 'name' as its primary key
  diffs = changesets.diff(oldObj, newObj, {children: 'name'});

  expect(diffs).to.eql([
    {
      type: '+-',
      key: [ 'name' ],
      value: 'smith',
      oldValue: 'joe'
    },
    {
      type: '+',
      key: [ 'coins', '2' ],
      value: 1
    },
    {
      type: '+-',
      key: [ 'children', '$name=kid1', 'age' ],
      value: 0,
      oldValue: 1
    },
    {
      type: '+',
      key: [ 'children', '$name=kid3' ],
      value: { name: 'kid3', age: 3 } },
    {
      type: '-',
      key: [ 'age' ],
      value: 55
    }
  ]);
```

### Apply changeset to an object to make a new version of the object
#### Examples:

```javascript

  var changesets = require('./index');
  var oldObj = {
    name: 'joe',
    age: 55,
    coins: [2, 5],
    children: [
      {name: 'kid1', age: 1 },
      {name: 'kid2', age: 2 }
    ]};


  # Assume children is an array of child object and the child object has 'name' as its primary key
  diffs = [
    {
      type: '+-',
      key: [ 'name' ],
      value: 'smith',
      oldValue: 'joe'
    },
    {
      type: '+',
      key: [ 'coins', '2' ],
      value: 1
    },
    {
      type: '+-',
      key: [ 'children', '$name=kid1', 'age' ],
      value: 0,
      oldValue: 1
    },
    {
      type: '+',
      key: [ 'children', '$name=kid3' ],
      value: { name: 'kid3', age: 3 } },
    {
      type: '-',
      key: [ 'age' ],
      value: 55
    }
  ]

  expect(changesets.applyChange(oldObj, diffs)).to.eql {
    name: 'smith',
    coins: [2, 5, 1],
    children: [
      {name: 'kid3', age: 3 },
      {name: 'kid1', age: 0 },
      {name: 'kid2', age: 2 }
    ]};

```


### Revert an object to previous state with a changeset
#### Examples:

```javascript

  var changesets = require('./index');

  var newObj = {
    name: 'smith',
    coins: [2, 5, 1],
    children: [
      {name: 'kid3', age: 3 },
      {name: 'kid1', age: 0 },
      {name: 'kid2', age: 2 }
    ]};

  # Assume children is an array of child object and the child object has 'name' as its primary key
  diffs = [
    {
      type: '+-',
      key: [ 'name' ],
      value: 'smith',
      oldValue: 'joe'
    },
    {
      type: '+',
      key: [ 'coins', '2' ],
      value: 1
    },
    {
      type: '+-',
      key: [ 'children', '$name=kid1', 'age' ],
      value: 0,
      oldValue: 1
    },
    {
      type: '+',
      key: [ 'children', '$name=kid3' ],
      value: { name: 'kid3', age: 3 } },
    {
      type: '-',
      key: [ 'age' ],
      value: 55
    }
  ]

  expect(changesets.revertChanges(newObj, diffs)).to.eql {
    name: 'joe',
    age: 55,
    coins: [2, 5],
    children: [
      {name: 'kid1', age: 1 },
      {name: 'kid2', age: 2 }
    ]};

```

## Get started

```
npm install changesets
```

## Run the test
```
npm run test
```

## Licence

The MIT License (MIT)

Copyright (c) 2013 viruschidai@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
