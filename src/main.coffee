fs = require 'fs'
path = require 'path'

Configuration = require './configuration'
Database = require './db/database'
Application = require './web/application'

config = new Configuration()
db = new Database(config.db)

userConfigFile = path.join __dirname, '..', 'config.js'
if fs.existsSync(userConfigFile)
    require(userConfigFile)(config)

if not fs.existsSync(config.uploadDir)
    fs.mkdirSync(config.uploadDir)
if not fs.existsSync(config.storageDir)
    fs.mkdirSync(config.storageDir)

if process.argv.length > 2
    if process.argv[2] in ['--adduser', '-a']
        db.on('ready', ->
            db.addUser().then((user) ->
                console.log 'Created user', JSON.stringify(user.attributes)
                process.exit 0
            ).catch((err) ->
                console.error 'Error creating user', err
                process.exit -1
            )
        )
    else if process.argv[2] in ['--listusers', '-l']
        db.on('ready', ->
            User = db.models.User
            User.fetchAll().then((users) ->
                users = users.map((user) -> JSON.stringify(user.attributes))
                users.forEach((user) -> console.log user)
                process.exit 0
            ).catch((err) ->
                console.error 'Error listing users', err
                process.exit -1
            )
        )
    else if process.argv[2] in ['--revokeuser', '-r']
        if process.argv.length < 4
            console.error "Usage: node #{process.argv[1]} --revokeuser <user key>"
            process.exit -1

        db.on('ready', ->
            User = db.models.User
            User.forge(key: process.argv[3]).fetch(require: true).then((user) ->
                key = user.get('key')
                return user.destroy()
            ).then( ->
                console.log "Deleted user #{process.argv[3]}"
                process.exit 0
            ).catch((err) ->
                console.error 'Deletion failed', err
                process.exit -1
            )
        )

else
    console.log 'Initializing webserver'
    app = new Application(config, db)
    console.log 'Starting delete expired images task'
    require('./expiretask')(config, db)
