mockery = require 'mockery'
{expect} = require 'chai'

describe 'socket.ipc', ->
  Client = null
  Server = null

  beforeEach ->
    mockery.enable
      useCleanCache: true

    Client = class Client
    Server = class Server

    mockery.registerMock './renderer/Client', Client
    mockery.registerMock './browser/Server', Server
    mockery.registerAllowable '../main/index'

  afterEach ->
    mockery.deregisterMock 'is-electron-renderer'
    mockery.deregisterMock './renderer/Client'
    mockery.deregisterMock './browser/Server'
    mockery.disable()

  it 'should export renderer/Client if isElectronRenderer is true', ->
    mockery.registerMock 'is-electron-renderer', true

    expect require '../main/index'
      .to.equal Client

  it 'should export browser/Server if isElectronRenderer is false', ->
    mockery.registerMock 'is-electron-renderer', false

    expect require '../main/index'
      .to.equal Server
