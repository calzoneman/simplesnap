UNAUTHORIZED = 401

module.exports = (config, db) ->
    return (req, res, next) ->
        if req.method.toLowerCase() not in ['post', 'put', 'delete']
            return next()

        if !req.header(config.authHeader)
            if config.allowAnonymousUploads
                return next()
            else
                res.status(UNAUTHORIZED).json(error: "Missing #{config.authHeader} header")
                return req.destroy()

        User = db.models.User
        User.forge(key: req.header(config.authHeader)).fetch(require: true).then((user) ->
            req.user = user
            next()
        ).catch((err) ->
            res.status(UNAUTHORIZED).json(error: "Invalid #{config.authHeader} ID")
            req.destroy()
        )
