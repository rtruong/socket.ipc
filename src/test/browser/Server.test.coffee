Namespace = require '../../main/browser/Namespace'
Server = require '../../main/browser/Server'
Socket = require '../../main/browser/Socket'
sinon = require 'sinon'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'
{expect} = require 'chai'

class Sender
  # coffeelint: disable=no_empty_functions
  send: ->
  # coffeelint: enable=no_empty_functions



class Event
  constructor: ->
    @sender = new Sender()



describe 'browser/Server', ->
  ipc = null
  server = null

  beforeEach ->
    ipc = new EventEmitter()
    server = new Server ipc

  describe 'constructor', ->
    it 'should support auto-instantiation', ->
      expect Server ipc
        .to.be.an.instanceof Server

  describe '.namespace()', ->
    it 'should be `/`', ->
      expect Server.namespace()
        .to.equal '/'

  describe '#name', ->
    it 'should be `/`', ->
      expect server.name
        .to.equal '/'

  describe '#of()', ->
    it 'should return Server instance for `/` namespace', ->
      expect server.of '/'
        .to.equal server

    it 'should create new Namespace instances as needed', ->
      namespace1 = server.of '/namespace1'

      expect namespace1
        .to.be.an.instanceof Namespace
      expect namespace1.name
        .to.equal '/namespace1'
      expect server.of '/namespace1'
        .to.equal namespace1

      expect server.of '/namespace2'
        .to.be.an.instanceof Namespace

  describe 'events', ->
    describe 'connection', ->
      it 'should #emit() on connect from `ipc`', ->
        clientUuid1 = uuid.v4()
        clientUuid2 = uuid.v4()
        listener1 = sinon.stub()
        listener2 = sinon.stub()

        server.on 'connection', listener1
        server.of '/foobar'
          .on 'connection', listener2

        ipc.emit "#{Server.uuid()}-connect", new Event(), clientUuid1
        ipc.emit "#{Server.uuid()}-connect", new Event(), clientUuid2, '/foobar'

        sinon.assert.calledWithExactly listener1, sinon.match.instanceOf Socket
        sinon.assert.calledWithExactly listener2, sinon.match.instanceOf Socket

      it 'should #emit() `connect` on `socket`', ->
        clientUuid = uuid.v4()
        listener = sinon.stub()
        event = new Event()
        sendStub = sinon.stub event.sender, 'send'

        ipc.emit "#{Server.uuid()}-connect", event, clientUuid

        sinon.assert.calledWithExactly sendStub, "#{Server.uuid()}-#{clientUuid}-event",
          name: 'connect'
          args: '[]'

      describe 'disconnect', ->
        it 'should remove `socket` from `sockets`', ->
          clientUuid1 = uuid.v4()
          clientUuid2 = uuid.v4()
          listener = sinon.stub()

          server.on 'connection', listener

          ipc.emit "#{Server.uuid()}-connect", new Event(), clientUuid1
          ipc.emit "#{Server.uuid()}-connect", new Event(), clientUuid1

          sinon.assert.calledTwice listener

          socket1 = listener.firstCall.args[0]
          socket2 = listener.secondCall.args[0]

          sinon.spy socket1, 'emit'
          sinon.spy socket2, 'emit'

          EventEmitter::emit.call socket1, 'disconnect'

          server.emit 'an event'
          sinon.assert.notCalled socket1.emit
          sinon.assert.calledOnce socket2.emit
