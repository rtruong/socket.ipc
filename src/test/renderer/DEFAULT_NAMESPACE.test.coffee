mockery = require 'mockery'
sinon = require 'sinon'
{expect} = require 'chai'

describe 'renderer/DEFAULT_NAMESPACE', ->
  SERVER = null

  beforeEach ->
    mockery.enable
      useCleanCache: true

    SERVER =
      namespace: sinon.stub()

    mockery.registerMock './SERVER', SERVER
    mockery.registerAllowable '../../main/renderer/DEFAULT_NAMESPACE'

  afterEach ->
    mockery.deregisterMock './SERVER'
    mockery.disable()

  it 'should export remote `socket.ipc` namespace()', ->
    expected = '/'

    SERVER.namespace.returns expected

    expect require '../../main/renderer/DEFAULT_NAMESPACE'
      .to.equal expected
