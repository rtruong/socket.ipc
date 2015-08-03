mockery = require 'mockery'
sinon = require 'sinon'
{expect} = require 'chai'

describe 'renderer/SERVER', ->
  remote = null

  beforeEach ->
    mockery.enable
      useCleanCache: true

    remote =
      require: sinon.stub()

    mockery.registerMock 'remote', remote
    mockery.registerAllowable '../../main/renderer/SERVER'

  afterEach ->
    mockery.deregisterMock 'remote'
    mockery.disable()

  it 'should export remote `socket.ipc` instance', ->
    SERVER = {}

    remote.require
      .withArgs 'socket.ipc'
      .returns SERVER

    expect require '../../main/renderer/SERVER'
      .to.equal SERVER
