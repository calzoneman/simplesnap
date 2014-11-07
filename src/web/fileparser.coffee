multiparty = require 'multiparty'

REQUEST_ENTITY_TOO_LARGE = 413

module.exports = (config) ->
    return (req, res, next) ->
        if req.method.toLowerCase() not in ['post', 'put']
            return next()

        form = new multiparty.Form(autoFiles: true, uploadDir: config.uploadDir)

        form.on('progress', (bytesReceived, bytesExpected) ->
            if bytesReceived > config.maxFileSize or bytesExpected > config.maxFileSize
                res.status(REQUEST_ENTITY_TOO_LARGE)
                req.destroy()
        )

        form.parse(req, (err, fields, files) ->
            if err
                return next(err)

            req.files = files
            for key, value of fields
                req.body[key] = fields[key][0]

            next()
        )
