mmmagic = require 'mmmagic'
Magic = mmmagic.Magic
winston = require 'winston'

UNSUPPORTED_MEDIA_TYPE = 415
INTERNAL_SERVER_ERROR = 500

module.exports = (config) ->
    return (req, res, next) ->
        if not req.files or not req.files.image
            return next()

        magic = new Magic(mmmagic.MAGIC_MIME_TYPE)

        file = req.files.image
        magic.detectFile(file.path, (err, mime) ->
            if err
                res.status(INTERNAL_SERVER_ERROR).json(error: 'Failed to detect mime type of image')
                req.destroy()
                winston.error 'Failed to detect mime type for %s', file, err
            else if mime not of config.allowedMimeTypes
                res.status(UNSUPPORTED_MEDIA_TYPE).json(error: "Illegal mime type #{mime}")
                req.destroy()
            else
                file.mime = mime
                file.extension = config.allowedMimeTypes[mime]
                next()
        )

