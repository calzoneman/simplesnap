express = require 'express'
path = require 'path'
ms = require 'ms'
Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs')

BAD_REQUEST = 400
NOT_FOUND = 404
INTERNAL_SERVER_ERROR = 500

class Application
    constructor: (@config, @db) ->
        @app = express()

        @app.use(require('./authorization')(config, db))
        @app.use(require('./fileparser')(config))
        @app.use(require('./detectmime')(config))

        extensions = (ext for mime, ext of @config.allowedMimeTypes).join('|')
        basePath = @config.basePath.replace(/\//g, '\\/')
        imagePath = "(#{basePath}[a-zA-Z0-9]+\.(?:#{extensions}))"
        @app.get(new RegExp(imagePath), @serveImage)
        @app.post('/upload', @uploadImage)
        @app.put('/upload', @uploadImage)
        @app.get('/images', @serveImageList)
        @app.get('/', @serveIndex)
        @app.use(@errorHandler)

        for [host, port] in @config.bindAddresses
            @app.listen(port, host)

    serveImageList: (req, res) =>
        if req.header(@config.authHeader)
            Image = @db.models.Image
            Image.fetchAll(user_key: req.header(@config.authHeader)).then((images) =>
                elems = images.map((image) =>
                    filepath = @config.basePath + image.get('filename')
                    return "#{req.protocol}://#{req.header('host')}#{filepath}"
                )

                res.json(images: elems)
            )
        else
            res.json(error: "No #{@config.authHeader} header present")

    serveIndex: (req, res) ->
        html =  """
                <!doctype html>
                <html>
                    <head>
                        <title>Simplesnap</title>
                        <meta charset="utf-8">
                    </head>
                    <body>
                        This server is running <a href="https://github.com/calzoneman/simplesnap">simplesnap</a>.
                    </body>
                </html>
                """
        res.send(html)

    serveImage: (req, res) =>
        res.sendFile(req.params[0], root: @config.storageDir)

    uploadImage: (req, res) =>
        if not req.files.image
            return res.status(BAD_REQUEST).json(error: 'Expected image in request body')

        if not req.body.expiration and @config.expirationLimit
            return res.status(BAD_REQUEST).json(error: 'Expiration is required')

        delay = null
        if req.body.expiration
            delay = ms(req.body.expiration)
            if not delay
                return res.status(BAD_REQUEST).json(error: 'Invalid expiration')
            else if delay > @config.expirationLimit
                limit = ms(@config.expirationLimit)
                return res.status(BAD_REQUEST).json(error: "Expiration exceeds limit of #{limit}")

        file = req.files.image
        file.expiration = delay
        data = null
        @db.addImage(file, req.header(@config.authHeader)).then((image) =>
            data =
                filename: @config.basePath + image.get('filename')
                expires: image.get('expires')
            return fs.renameAsync(file.path,
                    path.join(@config.storageDir, image.get('filename')))
        ).then( ->
            res.json(data)
        ).catch((err) ->
            res.status(INTERNAL_SERVER_ERROR).json(error: 'Upload failed (database error)')
            winston.error 'Upload failed:', err
        )

    errorHandler: (err, req, res, next) ->
        method = req.method.toLowerCase()
        if err.code == 'ENOENT'
            res.sendStatus(NOT_FOUND)
        else
            res.status(INTERNAL_SERVER_ERROR).json(error: 'Internal server error')

module.exports = Application
