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
        'image/png': 'png',
        'image/webp': 'webp',
        'image/svg': 'svg',
        'video/webm': 'webm'
    maxFileSize: 8 * 1024 * 1024
    uploadDir: path.resolve(__dirname, '..', 'uploads')
    storageDir: path.resolve(__dirname, '..', 'im')
    basePath: '/'
    allowAnonymousUploads: false
    authHeader: 'x-simplesnap-auth'
    expirationLimit: 30 * 24 * 60 * 60 * 1000
    bindAddresses: [ ['', 5000] ]


class Configuration
    constructor: (config) ->
        for key, val of DEFAULT
            this[key] = val

module.exports = Configuration
