numberComparator = (a, b) -> a - b

objectIdComparator = (a, b) ->
  if (!a || !a.id)
    return -1
  if (!b || !b.id)
    return 1
  a.id.localeCompare(b.id)

module.exports =
  describeStrategy: (description, strategy) ->
    describe description, ->
      priv = undefined

      describe 'starting empty', ->
        beforeEach ->
          priv = new strategy(comparator: numberComparator)

        it 'should not contain a value', ->
          expect(priv.contains(2)).to.eq(false)

        it 'should store its data in an array for easy testing', ->
          expect(priv.toArray()).to.deep.eq([])

        it 'should insert an element', ->
          priv.insert(4)
          expect(priv.toArray()).to.deep.eq([4])

        it 'should not fail to remove an element not found in set', ->
          priv.remove(4)

        it 'should return an iterator with no next or previous', ->
          iterator = priv.findIterator(4)
          expect(iterator.hasNext()).to.eq(false)
          expect(iterator.hasPrevious()).to.eq(false)
          expect(iterator.next()).to.eq(null)
          expect(iterator.previous()).to.eq(null)
          expect(iterator.value()).to.eq(null)

        it 'should return a beginIterator', ->
          iterator = priv.beginIterator()
          expect(iterator.value()).to.eq(null)

        it 'should return an endIterator', ->
          iterator = priv.endIterator()
          expect(iterator.value()).to.eq(null)

        it 'should do nothing in forEachImpl()', ->
          callback = sinon.spy()
          priv.forEachImpl(callback)
          expect(callback).not.to.have.been.called

      describe 'with some numbers', ->
        beforeEach ->
          priv = new strategy(comparator: numberComparator)
          # Insert in this order so binary tree isn't one-sided
          priv.insert(2)
          priv.insert(1)
          priv.insert(3)

        it 'should insert at the beginning', ->
          priv.insert(0)
          expect(priv.toArray()).to.deep.eq([0, 1, 2, 3])

        it 'should insert in the middle', ->
          priv.insert(2.5)
          expect(priv.toArray()).to.deep.eq([1, 2, 2.5, 3])

        it 'should insert at the end', ->
          priv.insert(4)
          expect(priv.toArray()).to.deep.eq([1, 2, 3, 4])

        it 'should remove from the beginning', ->
          priv.remove(1)
          expect(priv.toArray()).to.deep.eq([2, 3])

        it 'should remove from the end', ->
          priv.remove(3)
          expect(priv.toArray()).to.deep.eq([1, 2])

        it 'should remove from the middle', ->
          priv.remove(2)
          expect(priv.toArray()).to.deep.eq([1, 3])

        it 'should clear', ->
          priv.clear()
          expect(priv.toArray()).to.deep.eq([])

        it 'should allow insert after clear', ->
          priv.clear()
          priv.insert(4)
          priv.insert(2)
          expect(priv.toArray()).to.deep.eq([ 2, 4 ])

        it 'should contain the first value', ->
          expect(priv.contains(1)).to.eq(true)

        it 'should contain the last value', ->
          expect(priv.contains(3)).to.eq(true)

        it 'should contain a middle value', ->
          expect(priv.contains(2)).to.eq(true)

        it 'should not contain a value below the lowest', ->
          expect(priv.contains(0)).to.eq(false)

        it 'should not contain a value above the highest', ->
          expect(priv.contains(4)).to.eq(false)

        it 'should not contain a value in between two values', ->
          expect(priv.contains(1.5)).to.eq(false)

        it 'should return false from contain', ->
          expect(priv.contains(4)).to.eq(false)

        it 'should return a begin iterator', ->
          iterator = priv.beginIterator()
          expect(iterator.previous()).to.eq(null)
          expect(iterator.value()).to.eq(1)

        it 'should return an end iterator', ->
          iterator = priv.endIterator()
          expect(iterator.next()).to.eq(null)
          expect(iterator.value()).to.eq(null)

        it 'should find an iterator', ->
          iterator = priv.findIterator(2)
          expect(iterator.value()).to.eq(2)

        it 'should find an iterator between values', ->
          iterator = priv.findIterator(1.5)
          expect(iterator.value()).to.eq(2)

        it 'should find an iterator with a value above the max', ->
          iterator = priv.findIterator(3.5)
          expect(iterator.value()).to.eq(null)

        it 'should find an iterator with a value below the min', ->
          iterator = priv.findIterator(0.5)
          expect(iterator.value()).to.eq(1)

        it 'should find a previous iterator', ->
          iterator = priv.findIterator(2).previous()
          expect(iterator.value()).to.eq(1)

        it 'should find a next iterator', ->
          iterator = priv.findIterator(2).next()
          expect(iterator.value()).to.eq(3)

        it 'should step to previous from the end iterator', ->
          iterator = priv.endIterator().previous()
          expect(iterator.value()).to.eq(3)

        it 'should step to end from a previous iterator', ->
          iterator = priv.findIterator(3).next()
          expect(iterator.value()).to.eq(null)

        it 'should fail to setValue()', ->
          iterator = priv.findIterator(2)
          expect(-> iterator.setValue(2.5)).to.throw()

        it 'should iterate in forEachImpl', ->
          set = 'foo'
          thisArg = { testProperty: 'testValue' }
          spy = sinon.spy()
          priv.forEachImpl(spy, set, thisArg)
          expect(spy).to.have.callCount(3)
          expect(spy.thisValues[0]).to.eq(thisArg)
          expect(spy.args[0]).to.deep.eq([ 1, 0, set  ])
          expect(spy.args[1]).to.deep.eq([ 2, 1, set  ])
          expect(spy.args[2]).to.deep.eq([ 3, 2, set  ])

      describe 'with allowSetValue', ->
        beforeEach ->
          priv = new strategy(comparator: numberComparator, allowSetValue: true)
          priv.insert(1)
          priv.insert(2)

        it 'should allow you to use setValue(), even to do something stupid', ->
          iterator = priv.findIterator(2)
          iterator.setValue(0)
          expect(priv.toArray()).to.deep.eq([1, 0])

        it 'should not allow setValue() on an end iterator', ->
          iterator = priv.endIterator()
          expect(-> iterator.setValue(2.5)).to.throw()

      describe 'with objects', ->
        beforeEach ->
          priv = new strategy(comparator: objectIdComparator)
          priv.insert({id: '222'})
          priv.insert({id: '333'})
          priv.insert({id: '111'})

        it 'should not contain a number', ->
          expect(priv.contains(2)).to.eq(false)

        it 'should not contain an object', ->
          expect(priv.contains({id: '5'})).to.eq(false)

        it 'should contain an object', ->
          expect(priv.contains({id: '111'})).to.eq(true)
          expect(priv.contains({id: '222'})).to.eq(true)
          expect(priv.contains({id: '333'})).to.eq(true)

        it 'should remove an object properly', ->
          array = priv.toArray()
          expect(array.length).to.eq(3)

          priv.remove({id: '222'})

          array = priv.toArray()

          expect(array.length).to.eq(2)
          expect(array[0].id).to.eq('111')
          expect(array[1].id).to.eq('333')
