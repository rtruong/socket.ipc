Broadcaster = require '../../main/browser/Broadcaster'
Socket = require '../../main/browser/Socket'
sinon = require 'sinon'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'

describe 'browser/Broadcaster', ->
  socket1 = null
  socket2 = null
  socket3 = null
  socketFilter = null
  broadcaster = null

  beforeEach ->
    ipc = new EventEmitter()
    namespace = '/'
    sender = {}
    serverUuid = uuid.v4()
    sockets = []

    socket1 = new Socket uuid.v4(), ipc, namespace, sender, serverUuid, sockets
    socket2 = new Socket uuid.v4(), ipc, namespace, sender, serverUuid, sockets
    socket3 = new Socket uuid.v4(), ipc, namespace, sender, serverUuid, sockets
    socketFilter = sinon.stub()
    broadcaster = new Broadcaster sockets, socketFilter

    sockets.push socket1
    sockets.push socket2
    sockets.push socket3
    sinon.stub socket1, 'emit'
    sinon.stub socket2, 'emit'
    sinon.stub socket3, 'emit'

  describe '#emit()', ->
    it 'should #emit() to all `sockets` satisfying `socketFilter`', ->
      socketFilter
        .returns true
        .withArgs socket2
        .returns false

      broadcaster.emit 'an event', 'first argument', 'second argument'

      sinon.assert.calledWithExactly socket1.emit, 'an event', 'first argument', 'second argument'
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledWithExactly socket3.emit, 'an event', 'first argument', 'second argument'

  describe '#to()', ->
    it 'should #emit() to all `sockets` in specified room(s) that satisfy `socketFilter`', ->
      socket1.join 'room 1'
      socket2.join 'room 1'
      socket3.join 'room 1'

      socket2.join 'room 2'
      socket3.join 'room 2'

      socketFilter
        .returns true
        .withArgs socket2
        .returns false

      broadcaster.to 'room 1'
        .emit 'an event'

      sinon.assert.calledOnce socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledOnce socket3.emit

      broadcaster.to 'room 2'
        .emit 'an event'

      sinon.assert.calledOnce socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledTwice socket3.emit

      broadcaster.to 'room 1'
        .to 'room 2'
        .emit 'an event'

      sinon.assert.calledTwice socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledThrice socket3.emit

  describe '#in()', ->
    it 'should #emit() to all `sockets` in specified room(s) that satisfy `socketFilter`', ->
      socket1.join 'room 1'
      socket2.join 'room 1'
      socket3.join 'room 1'

      socket2.join 'room 2'
      socket3.join 'room 2'

      socketFilter
        .returns true
        .withArgs socket2
        .returns false

      broadcaster.in 'room 1'
        .emit 'an event'

      sinon.assert.calledOnce socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledOnce socket3.emit

      broadcaster.in 'room 2'
        .emit 'an event'

      sinon.assert.calledOnce socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledTwice socket3.emit

      broadcaster.in 'room 1'
        .in 'room 2'
        .emit 'an event'

      sinon.assert.calledTwice socket1.emit
      sinon.assert.notCalled socket2.emit
      sinon.assert.calledThrice socket3.emit
