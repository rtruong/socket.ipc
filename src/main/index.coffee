isElectronRenderer = require 'is-electron-renderer'

module.exports = if isElectronRenderer then require './renderer/Client' else require './browser/Server'
