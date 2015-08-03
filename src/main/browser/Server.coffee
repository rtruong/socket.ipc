Namespace = require './Namespace'
Socket = require './Socket'
_ = require 'lodash'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'

DEFAULT_NAMESPACE = '/'
SERVER_UUID = uuid.v4()

module.exports = class Server extends Namespace
  @namespace: ->
    DEFAULT_NAMESPACE

  @uuid: ->
    SERVER_UUID

  constructor: (ipc) ->
    return new Server arguments... if @ not instanceof Server

    sockets = []
    namespaces = {}
    namespaces[DEFAULT_NAMESPACE] = @

    @of = (namespace) ->
      namespaces[namespace] = namespaces[namespace] or new Namespace namespace, sockets

    ipc.on "#{SERVER_UUID}-connect", (event, clientUuid, namespace = DEFAULT_NAMESPACE) =>
      socket = new Socket clientUuid, ipc, namespace, event.sender, SERVER_UUID, sockets
      sockets.push socket
      socket.emit 'connect'
      _namespace = @of namespace

      socket.once 'disconnect', ->
        _.pull sockets, socket

      EventEmitter::emit.call _namespace, 'connection', socket

    super DEFAULT_NAMESPACE, sockets
