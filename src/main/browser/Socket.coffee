Broadcaster = require './Broadcaster'
_ = require 'lodash'
{EventEmitter} = require 'events'

module.exports = class Socket extends EventEmitter
  constructor: (@id, ipc, namespace, sender, serverUuid, sockets) ->
    rooms = []

    @broadcast = new Broadcaster sockets, (socket) => namespace is socket.namespace() and @ isnt socket

    @namespace = ->
      namespace

    @rooms = =>
      [ @id ].concat rooms

    @emit = (event, args...) ->
      sender.send "#{serverUuid}-#{@id}-event",
        name: event
        args: JSON.stringify args

    @join = (room) ->
      rooms.push room

    @leave = (room) ->
      _.pull rooms, room

    ipc.on "#{serverUuid}-#{@id}-event", (_event, event) =>
      args = [ event.name ].concat JSON.parse event.args

      if event.ack
        args.push _.once (args...) =>
          sender.send "#{serverUuid}-#{@id}-#{event.uuid}-ack",
            args: JSON.stringify args

      EventEmitter::emit.apply @, args

    @on 'disconnect', =>
      ipc.removeAllListeners "#{serverUuid}-#{@id}-event"
      @removeAllListeners()
