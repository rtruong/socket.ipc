# socket.ipc

[![Build Status](https://travis-ci.org/rtruong/socket.ipc.svg?branch=master)](https://travis-ci.org/rtruong/socket.ipc)
[![Coverage Status](https://coveralls.io/repos/rtruong/socket.ipc/badge.svg?branch=master&service=github)](https://coveralls.io/github/rtruong/socket.ipc?branch=master)
[![Dependency Status](https://david-dm.org/rtruong/socket.ipc.svg)](https://david-dm.org/rtruong/socket.ipc)
[![devDependency Status](https://david-dm.org/rtruong/socket.ipc/dev-status.svg)](https://david-dm.org/rtruong/socket.ipc#info=devDependencies)

Socket.IPC lets you use [Socket.IO](http://socket.io/) semantics for [Electron](http://electron.atom.io/) [IPC](https://github.com/atom/electron/blob/master/docs/api/ipc-main-process.md).

## How to use
An example of sending messages from the main process to the renderer process, and vice versa.

```
// In main process.
var ipc = require('ipc');
var io = require('socket.ipc')(ipc);
io.on('connection', function (socket) {
  socket.on('asynchronous-message', function (arg, fn) {
    console.log(arg);  // prints "ping"
    fn('pong');
  });

  socket.emit('ping', 'whoooooooh!');
});
```

```
// In renderer process (web page).
var io = require('socket.ipc');
var socket = io();
socket.on('connect', function () {
  socket.emit('asynchronous-message', 'ping', function (arg) {
    console.log(arg); // prints "pong"
  });

  socket.on('ping', function (message) {
    console.log(message);  // Prints "whoooooooh!"
  });
});
```
