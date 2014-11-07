multiparty = require 'multiparty'

REQUEST_ENTITY_TOO_LARGE = 413

module.exports = (config) ->
    return (req, res, next) ->
        if req.method.toLowerCase() not in ['post', 'put']
            return next()

        form = new multiparty.Form(autoFiles: true, uploadDir: config.uploadDir)

        form.on('progress', (bytesReceived, bytesExpected) ->
            if bytesReceived > config.maxFileSize or bytesExpected > config.maxFileSize
                res.status(REQUEST_ENTITY_TOO_LARGE).json(error: 'Upload exceeds maximum size')
                req.destroy()
        )

        form.parse(req, (err, fields, files) ->
            if err
                return next(err)

            req.files = {}
            for key, value of files
                req.files[key] = value[0]

            req.body = req.body or {}
            for key, value of fields
                req.body[key] = fields[key][0]

            next()
        )
