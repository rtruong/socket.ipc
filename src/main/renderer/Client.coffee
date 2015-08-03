$ = require 'jquery'
DEFAULT_NAMESPACE = require './DEFAULT_NAMESPACE'
SERVER_UUID = require './SERVER_UUID'
_ = require 'lodash'
ipc = require 'ipc'
uuid = require 'node-uuid'
{EventEmitter} = require 'events'

module.exports = class Client extends EventEmitter
  constructor: (namespace = DEFAULT_NAMESPACE) ->
    return new Client arguments... if @ not instanceof Client

    clientUuid = uuid.v4()
    acks = []

    @emit = (event, args...) ->
      eventUuid = uuid.v4()
      callback = _.last args
      ack = _.isFunction callback

      if ack
        acks.push eventUuid
        ipc.once "#{SERVER_UUID}-#{clientUuid}-#{eventUuid}-ack", (ack) ->
          _.pull acks, eventUuid
          callback.apply @, JSON.parse ack.args

      ipc
        .send "#{SERVER_UUID}-#{clientUuid}-event",
          uuid: eventUuid
          name: event
          args: JSON.stringify if ack then args.slice 0, -1 else args
          ack: ack

    @send = (message, callback) =>
      _message = JSON.stringify message

      if _.isFunction callback then @emit 'message', _message, callback else @emit 'message', _message

    @disconnect = =>
      @emit 'disconnect'
      ipc.removeAllListeners "#{SERVER_UUID}-#{clientUuid}-event"
      ipc.removeAllListeners "#{SERVER_UUID}-#{clientUuid}-#{eventUuid}-ack" for eventUuid in acks
      @removeAllListeners()

    ipc
      .on "#{SERVER_UUID}-#{clientUuid}-event", (event) =>
        EventEmitter::emit.apply @, [ event.name ].concat JSON.parse event.args
      .send "#{SERVER_UUID}-connect", clientUuid, namespace

    $ window
      .unload @disconnect
