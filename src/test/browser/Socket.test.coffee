Socket = require '../../main/browser/Socket'
sinon = require 'sinon'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'
{expect} = require 'chai'

describe 'browser/Socket', ->
  serverUuid = null
  clientUuid = null
  ipc = null
  namespace = null
  sender = null
  sockets = null
  socket = null

  beforeEach ->
    serverUuid = uuid.v4()
    clientUuid = uuid.v4()
    ipc = new EventEmitter()
    namespace = '/'
    sender = {}
    sockets = []
    socket = new Socket clientUuid, ipc, namespace, sender, serverUuid, sockets

    sockets.push socket

  describe '#id', ->
    it 'should be initialized with `id`', ->
      expect socket.id
        .to.equal clientUuid

  describe '#broadcast', ->
    it 'should broadcast to everyone else in the same namespace', ->
      anotherSocket = new Socket uuid.v4(), ipc, namespace, sender, serverUuid, sockets
      yetAnotherSocket = new Socket uuid.v4(), ipc, namespace, sender, serverUuid, sockets
      differentNamespace = new Socket uuid.v4(), ipc, '/foobar', sender, serverUuid, sockets

      sockets.push anotherSocket
      sockets.push yetAnotherSocket
      sockets.push differentNamespace

      sinon.stub socket, 'emit'
      sinon.stub anotherSocket, 'emit'
      sinon.stub yetAnotherSocket, 'emit'
      sinon.stub differentNamespace, 'emit'

      socket.broadcast.emit 'an event', 'first argument', 'second argument'

      sinon.assert.notCalled socket.emit
      sinon.assert.calledWithExactly anotherSocket.emit, 'an event', 'first argument', 'second argument'
      sinon.assert.calledWithExactly yetAnotherSocket.emit, 'an event', 'first argument', 'second argument'
      sinon.assert.notCalled differentNamespace.emit

  describe '#namespace()', ->
    it 'should return `namespace`', ->
      expect socket.namespace()
        .to.equal namespace

  describe '#rooms()', ->
    it 'should include #id as a room by default', ->
      expect socket.rooms()
        .to.eql [ clientUuid ]

  describe '#emit()', ->
    it 'should #send() event to `sender`', ->
      sendStub = sender.send = sinon.stub()

      socket.emit 'an event', 'first argument',
        second: 'argument'

      sinon.assert.calledWithExactly sendStub, "#{serverUuid}-#{clientUuid}-event",
        name: 'an event'
        args: '["first argument",{"second":"argument"}]'

  describe '#join()', ->
    it 'should add `room` to #rooms()', ->
      expect socket.rooms()
        .to.eql [ clientUuid ]

      socket.join 'one room'
      expect socket.rooms()
        .to.eql [ clientUuid, 'one room' ]

      socket.join 'another room'
      expect socket.rooms()
        .to.eql [ clientUuid, 'one room', 'another room' ]

  describe '#leave()', ->
    it 'should remove `room` from #rooms()', ->
      socket.join 'one room'
      socket.join 'another room'
      expect socket.rooms()
        .to.eql [ clientUuid, 'one room', 'another room' ]

      socket.leave 'one room'
      expect socket.rooms()
        .to.eql [ clientUuid, 'another room' ]

      socket.leave 'another room'
      expect socket.rooms()
        .to.eql [ clientUuid ]

  describe 'events', ->
    it 'should #emit() when event is received from `ipc`', ->
      listener = sinon.stub()

      socket.on 'an event', listener
      ipc.emit "#{serverUuid}-#{clientUuid}-event", null,
        name: 'an event'
        args: '["first argument",{"second":"argument"}]'

      sinon.assert.calledWithExactly listener, 'first argument',
        second: 'argument'

    it 'should #emit() with callback if event requests `ack`', ->
      eventUuid = uuid.v4()
      listener = sinon.stub()
      sendStub = sender.send = sinon.stub()

      socket.on 'an event', listener
      ipc.emit "#{serverUuid}-#{clientUuid}-event", null,
        uuid: eventUuid
        name: 'an event'
        args: '["first argument","second argument"]'
        ack: true

      sinon.assert.calledOnce listener
      sinon.assert.calledWithExactly listener, 'first argument', 'second argument', sinon.match.func

      listener.firstCall.args[2] 'ack first argument',
        second: 'ack argument'

      sinon.assert.calledOnce sendStub
      sinon.assert.calledWithExactly sendStub, "#{serverUuid}-#{clientUuid}-#{eventUuid}-ack",
        args: '["ack first argument",{"second":"ack argument"}]'

      listener.firstCall.args[2]()
      sinon.assert.calledOnce sendStub

    describe 'disconnect', ->
      it 'should #removeAllListeners() from `ipc`', ->
        removeAllListenersSpy = sinon.spy ipc, 'removeAllListeners'

        EventEmitter::emit.call socket, 'disconnect'

        sinon.assert.calledWithExactly removeAllListenersSpy, "#{serverUuid}-#{clientUuid}-event"

      it 'should #removeAllListeners()', ->
        removeAllListenersSpy = sinon.spy socket, 'removeAllListeners'

        EventEmitter::emit.call socket, 'disconnect'

        sinon.assert.calledWithExactly removeAllListenersSpy
