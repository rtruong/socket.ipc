_ = require 'lodash'
mockery = require 'mockery'
sinon = require 'sinon'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'
{expect} = require 'chai'
{jsdom} = require 'jsdom'

class Ipc extends EventEmitter
  # coffeelint: disable=no_empty_functions
  send: ->
  # coffeelint: enable=no_empty_functions



describe 'renderer/Client', ->
  Client = null
  DEFAULT_NAMESPACE = null
  SERVER_UUID = null
  ipc = null
  window = null

  beforeEach ->
    mockery.enable
      useCleanCache: true
      warnOnUnregistered: false

    global.document = jsdom '<html><body></body></html>'
    window = global.window = document.defaultView

    DEFAULT_NAMESPACE = '/'
    SERVER_UUID = uuid.v4()
    ipc = new Ipc()

    mockery.registerMock './DEFAULT_NAMESPACE', DEFAULT_NAMESPACE
    mockery.registerMock './SERVER_UUID', SERVER_UUID
    mockery.registerMock 'ipc', ipc

    Client = require '../../main/renderer/Client'

  afterEach ->
    window = null
    delete global.window
    delete global.document

    mockery.deregisterMock 'ipc'
    mockery.deregisterMock './SERVER_UUID'
    mockery.deregisterMock './DEFAULT_NAMESPACE'
    mockery.disable()

  describe 'constructor', ->
    it 'should support auto-instantiation', ->
      expect Client()
        .to.be.an.instanceof Client

    it 'should connect over `ipc` with DEFAULT_NAMESPACE when no `namespace` is specified', ->
      sendStub = sinon.stub ipc, 'send'

      new Client()

      sinon.assert.calledWithExactly sendStub, "#{SERVER_UUID}-connect", sinon.match.string, DEFAULT_NAMESPACE

    it 'should connect over `ipc` with `namespace`', ->
      sendStub = sinon.stub ipc, 'send'

      new Client('/foo/bar')

      sinon.assert.calledWithExactly sendStub, "#{SERVER_UUID}-connect", sinon.match.string, '/foo/bar'

  describe '#emit()', ->
    sendStub = null
    client = null
    clientUuid = null

    beforeEach ->
      sendStub = sinon.stub ipc, 'send'
      client = new Client()
      clientUuid = sendStub.firstCall.args[1]

    it 'should #send() event to `ipc`', ->
      client.emit 'an event', 'first argument',
        second: 'argument'

      sinon.assert.calledWithExactly sendStub, "#{SERVER_UUID}-#{clientUuid}-event",
        uuid: sinon.match.string
        name: 'an event'
        args: '["first argument",{"second":"argument"}]'
        ack: false

    it 'should invoke callback on ack', ->
      callback = sinon.stub()
      client.emit 'an event', 'first argument', 'second argument', callback
      sinon.assert.calledWithExactly sendStub, "#{SERVER_UUID}-#{clientUuid}-event",
        uuid: sinon.match.string
        name: 'an event'
        args: '["first argument","second argument"]'
        ack: true

      eventUuid = sendStub.secondCall.args[1].uuid

      ipc.emit "#{SERVER_UUID}-#{clientUuid}-#{eventUuid}-ack",
        args: '["first ack","second ack"]'
      sinon.assert.calledWithExactly callback, 'first ack', 'second ack'

      ipc.emit "#{SERVER_UUID}-#{clientUuid}-#{eventUuid}-ack",
        args: '["third ack","fourth ack"]'
      sinon.assert.neverCalledWith callback, 'third ack', 'fourth ack'

  describe '#send()', ->
    client = null
    emitStub = null

    beforeEach ->
      client = new Client()
      emitStub = sinon.stub client, 'emit'

    it 'should #emit() `message`', ->
      message =
        first: 'argument'
        second: 'argument'

      client.send message

      sinon.assert.calledWithExactly emitStub, 'message', '{"first":"argument","second":"argument"}'

    it 'should #emit() `message` with `callback`', ->
      message =
        first: 'argument'
        second: 'argument'
      # coffeelint: disable=no_empty_functions
      callback = ->
      # coffeelint: enable=no_empty_functions

      client.send message, callback

      sinon.assert.calledWithExactly emitStub, 'message', '{"first":"argument","second":"argument"}', callback

  describe '#disconnect()', ->
    sendStub = null
    client = null
    clientUuid = null

    beforeEach ->
      sendStub = sinon.stub ipc, 'send'
      client = new Client()
      clientUuid = sendStub.firstCall.args[1]

    it 'should #emit() `disconnect`', ->
      emitStub = sinon.stub client, 'emit'

      client.disconnect()

      sinon.assert.calledWithExactly emitStub, 'disconnect'

    it 'should #removeAllListeners() for events from `ipc`', ->
      removeAllListenersStub = sinon.stub ipc, 'removeAllListeners'

      client.disconnect()

      sinon.assert.calledWithExactly removeAllListenersStub, "#{SERVER_UUID}-#{clientUuid}-event"

    it 'should #removeAllListeners() for outstanding acks from `ipc`', ->
      # coffeelint: disable=no_empty_functions
      client.emit 'an event', ->
      client.emit 'another event', ->
      # coffeelint: enable=no_empty_functions

      eventUuid1 = sendStub.secondCall.args[1].uuid
      eventUuid2 = sendStub.thirdCall.args[1].uuid

      ipc.emit "#{SERVER_UUID}-#{clientUuid}-#{eventUuid2}-ack",
        args: '["an ack"]'

      removeAllListenersStub = sinon.stub ipc, 'removeAllListeners'

      client.disconnect()

      sinon.assert.calledWithExactly removeAllListenersStub, "#{SERVER_UUID}-#{clientUuid}-#{eventUuid1}-ack"
      sinon.assert.neverCalledWith removeAllListenersStub, "#{SERVER_UUID}-#{clientUuid}-#{eventUuid2}-ack"

    it 'should #removeAllListeners()', ->
      removeAllListenersStub = sinon.stub client, 'removeAllListeners'

      client.disconnect()

      sinon.assert.calledWithExactly removeAllListenersStub

  describe 'events', ->
    it 'should #emit() when event is received from `ipc`', ->
      sendStub = sinon.stub ipc, 'send'
      client = new Client()
      clientUuid = sendStub.firstCall.args[1]
      listener = sinon.stub()

      client.on 'an event', listener

      ipc.emit "#{SERVER_UUID}-#{clientUuid}-event",
        name: 'an event'
        args: '["first argument",{"second":"argument"}]'

      sinon.assert.calledWithExactly listener, 'first argument',
        second: 'argument'

  describe 'window', ->
    $ = null

    beforeEach ->
      $ = require 'jquery'

    describe 'unload()', ->
      it 'should #disconnect()', ->
        client = new Client()
        emitStub = sinon.stub client, 'emit'

        $ window
          .unload()

        sinon.assert.calledWithExactly emitStub, 'disconnect'
