express = require 'express'
path = require 'path'
ms = require 'ms'

BAD_REQUEST = 400
INTERNAL_SERVER_ERROR = 500

class Application
    constructor: (@config, @db) ->
        @app = express()

        @app.use(require('./authorization')(config, db))
        @app.use(require('./fileparser')(config))
        @app.use(require('./detectmime')(config))

        extensions = [mime for mime, ext in @config.allowedMimeTypes]
        imagePath = "(#{@config.basePath.replace(/\//g, '\\/')}[a-zA-Z0-9]+\.(?:#{extensions}))"
        @app.get(new RegExp(imagePath), @serveImage)
        @app.post('/upload', @uploadImage)
        @app.put('/upload', @uploadImage)
        @app.get('/', @serveIndex)

        for [host, port] in @config.bindAddresses
            @app.listen(port, host)

    serveIndex: (req, res) =>
        if req.header(@config.authHeader)
            Image = @db.models.Image
            Image.fetchAll(user_key: req.header(@config.authHeader)).then((images) ->
                elems = images.map((image) ->
                    "<li><a href=\"#{image.get('filename')}\">#{image.get('filename')}</a></li>"
                )
                html =  """
                        <!doctype html>
                        <html>
                            <head>
                                <title>Image List</title>
                                <meta charset="utf-8">
                            </head>
                            <body>
                                <ul>
                                    #{elems}
                                </ul>
                            </body>
                        </html>
                        """
                res.send(html)
            )
        else
            html =  """
                    <!doctype html>
                    <html>
                        <head>
                            <title>Image List</title>
                            <meta charset="utf-8">
                        </head>
                        <body>
                            Unable to list images (no <code>#{@config.authHeader}</code> header present)
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
        @db.addImage(file, req.header(@config.authHeader)).then((image) ->
            res.json(filename: image.get('filename'), expires: image.get('expires'))
        ).catch((err) ->
            res.status(INTERNAL_SERVER_ERROR).json(error: 'Upload failed (database error)')
            winston.error 'Upload failed:', err
        )

module.exports = Application
