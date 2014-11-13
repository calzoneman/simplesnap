fs = require 'fs'
path = require 'path'
Promise = require 'bluebird'
Datastore = require 'nedb'

Configuration = require './configuration'
Database = require './db/database'

main = ->
    config = new Configuration()
    if fs.existsSync(path.join(__dirname, '..', 'config.js'))
        require(path.join(__dirname, '..', 'config.js'))(config)

    db = new Database(config.db)
    neImages = new Datastore(filename: path.join(__dirname, '..', 'images.db'))
    neImages.loadDatabase()

    db.on('ready', ->
        Image = db.models.Image
        neImages.find({}, (err, docs) ->
            if err
                console.error err
                process.exit -1

            Promise.all(docs.map((doc) ->
                return Image.forge(filename: doc.path.replace(/^\//, ''), expires: doc.expires)
                    .save()
                    .tap((image) -> console.log "Migrated #{image.get('filename')}")
            )).then( ->
                console.log 'Successful import'
                console.log 'Verify that the database was imported correctly and then it is safe to
                             remove images.db'
                process.exit 0
            ).catch((err) ->
                console.error err
                process.exit -1
            )
        )
    )

main()
