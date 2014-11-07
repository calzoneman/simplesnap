express = require 'express'
path = require 'path'

class Application
    constructor: (@config, @db) ->
        @app = express()

        extensions = [mime for mime, ext in @config.allowedMimeTypes]
        imagePath = "(#{@config.basePath.replace(/\//g, '\\/')}[a-zA-Z0-9]+\.(?:#{extensions}))"
        @app.get(new RegExp(imagePath), @serveImage)
        @app.get('/', @serveIndex)

        for [host, port] in @config.bindAddresses
            @app.listen(port, host)

    serveIndex: (req, res) ->
        res.sendFile(path.resolve(__dirname, '..', '..', 'index.html'))

    serveImage: (req, res) ->
        res.sendFile(req.params[0], root: @config.storageDir)

module.exports = Application
