Promise = require 'bluebird'
fs = Promise.promisifyAll(require 'fs')
path = require 'path'

module.exports = (config, db) ->
    clearExpiredImages = ->
        Image = db.models.Image
        Image.query('where', 'expires', '<', Date.now()).fetchAll().then((collection) ->
            return Promise.all(collection.models.map((image) ->
                file = path.join(config.storageDir, image.get('filename'))
                return fs.unlinkAsync(file).then( ->
                    return image.destroy()
                )
            ))
        ).then((results) ->
            if results.length > 0
                console.log 'Deleted %d expired images', results.length
        ).catch((err) ->
            console.error 'Error deleting expired images', err
        )

    clearExpiredImages()
    setInterval(clearExpiredImages, config.deleteExpiredInterval)
