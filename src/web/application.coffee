express = require 'express'
path = require 'path'

class Application
    constructor: (@config, @db) ->
        @app = express()

        @app.use(require('./authorization')(config, db))
        @app.use(require('./fileparser')(config))

        extensions = [mime for mime, ext in @config.allowedMimeTypes]
        imagePath = "(#{@config.basePath.replace(/\//g, '\\/')}[a-zA-Z0-9]+\.(?:#{extensions}))"
        @app.get(new RegExp(imagePath), @serveImage)
        @app.get('/', @serveIndex)

        for [host, port] in @config.bindAddresses
            @app.listen(port, host)

    serveIndex: (req, res) ->
        res.redirect('https://github.com/calzoneman/simplesnap')

    serveImage: (req, res) ->
        res.sendFile(req.params[0], root: @config.storageDir)

module.exports = Application
