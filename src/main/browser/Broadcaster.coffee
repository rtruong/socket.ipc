_ = require 'lodash'

module.exports = class Broadcaster
  constructor: (sockets, socketFilter, rooms = []) ->
    @emit = (event, args...) ->
      _sockets = _.filter sockets, (socket) ->
        inRoom = not rooms.length or _.some socket.rooms(), (room) ->
          _.contains rooms, room

        inRoom and socketFilter socket

      _.invoke _sockets, 'emit', event, args...

    @to = @in = (room) ->
      new Broadcaster sockets, socketFilter, rooms.concat room
