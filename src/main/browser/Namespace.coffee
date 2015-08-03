Broadcaster = require './Broadcaster'
{EventEmitter} = require 'events'

module.exports = class Namespace extends EventEmitter
  constructor: (@name, sockets) ->
    _sockets = @sockets = new Broadcaster sockets, (socket) =>
      @name is socket.namespace()

    @emit = (event, args...) ->
      _sockets.emit event, args...

    @to = (room) ->
      _sockets.to room

    @in = (room) ->
      _sockets.in room
