mockery = require 'mockery'
sinon = require 'sinon'
uuid = require 'node-uuid'
{expect} = require 'chai'

describe 'renderer/SERVER_UUID', ->
  SERVER = null

  beforeEach ->
    mockery.enable
      useCleanCache: true

    SERVER =
      uuid: sinon.stub()

    mockery.registerMock './SERVER', SERVER
    mockery.registerAllowable '../../main/renderer/SERVER_UUID'

  afterEach ->
    mockery.deregisterMock './SERVER'
    mockery.disable()

  it 'should export remote `socket.ipc` uuid()', ->
    expected = uuid.v4()

    SERVER.uuid.returns expected

    expect require '../../main/renderer/SERVER_UUID'
      .to.equal expected
