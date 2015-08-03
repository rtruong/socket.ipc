Broadcaster = require '../../main/browser/Broadcaster'
Namespace = require '../../main/browser/Namespace'
Socket = require '../../main/browser/Socket'
sinon = require 'sinon'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'
{expect} = require 'chai'

describe 'browser/Namespace', ->
  socket1 = null
  socket2 = null
  socket3 = null
  namespace = null

  beforeEach ->
    ipc = new EventEmitter()
    sender = {}
    serverUuid = uuid.v4()
    sockets = []

    socket1 = new Socket uuid.v4(), ipc, '/', sender, serverUuid, sockets
    socket2 = new Socket uuid.v4(), ipc, '/', sender, serverUuid, sockets
    socket3 = new Socket uuid.v4(), ipc, '/foobar', sender, serverUuid, sockets
    namespace = new Namespace '/', sockets

    sockets.push socket1
    sockets.push socket2
    sockets.push socket3
    sinon.stub socket1, 'emit'
    sinon.stub socket2, 'emit'
    sinon.stub socket3, 'emit'

  describe '#name', ->
    it 'should be initialized with `name`', ->
      expect namespace.name
        .to.equal '/'

  describe '#sockets', ->
    it 'should be a Broadcaster', ->
      expect namespace.sockets
        .to.be.an.instanceof Broadcaster

    it 'should broadcast to everyone in `namespace`', ->
      namespace.sockets.emit 'an event', 'first argument', 'second argument'

      sinon.assert.calledWithExactly socket1.emit, 'an event', 'first argument', 'second argument'
      sinon.assert.calledWithExactly socket2.emit, 'an event', 'first argument', 'second argument'
      sinon.assert.notCalled socket3.emit

  describe '#emit()', ->
    it 'should delegate to #sockets', ->
      emitSpy = sinon.spy namespace.sockets, 'emit'

      namespace.emit 'an event', 'first argument', 'second argument'

      sinon.assert.calledWithExactly emitSpy, 'an event', 'first argument', 'second argument'

  describe '#to()', ->
    it 'should delegate to #sockets', ->
      toSpy = sinon.spy namespace.sockets, 'to'
      broadcaster = namespace.to 'some room'

      sinon.assert.calledOnce toSpy
      sinon.assert.calledWithExactly toSpy, 'some room'
      expect broadcaster
        .to.equal toSpy.firstCall.returnValue

  describe '#in()', ->
    it 'should delegate to #sockets', ->
      inSpy = sinon.spy namespace.sockets, 'in'
      broadcaster = namespace.in 'some room'

      sinon.assert.calledOnce inSpy
      sinon.assert.calledWithExactly inSpy, 'some room'
      expect broadcaster
        .to.equal inSpy.firstCall.returnValue
