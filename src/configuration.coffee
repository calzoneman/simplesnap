path = require 'path'

DEFAULT =
    db:
        client: 'sqlite3'
        connection:
            filename: path.resolve(__dirname, '..', 'snap.sqlite')
    allowedMimeTypes:
        'image/bmp': 'bmp',
        'image/gif': 'gif',
        'image/jpeg': 'jpg',
        'image/png': 'png'
    maxFileSize: 8 * 1024 * 1024
    storageDir: path.resolve(__dirname, '..', 'im')
    basePath: '/'
    allowAnonymousUploads: false
    bindAddresses: [ ['0.0.0.0', 5000] ]


class Configuration
    constructor: (config) ->
        @config = {}
        for key, val of DEFAULT
            @config[key] = val

    getDatabaseConfiguration: ->
        return @config.db


module.exports = Configuration
