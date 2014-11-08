fs = require 'fs'
winston = require 'winston'

Configuration = require './configuration'
Database = require './db/database'
Application = require './web/application'

config = new Configuration()
db = new Database(config.db)

if not fs.existsSync(config.uploadDir)
    fs.mkdirSync(config.uploadDir)
if not fs.existsSync(config.storageDir)
    fs.mkdirSync(config.storageDir)

if process.argv.length > 2
    if process.argv[2] in ['--adduser', '-a']
        db.on('ready', ->
            db.addUser().then((user) ->
                winston.info 'Created user', JSON.stringify(user.attributes)
                process.exit 0
            ).catch((err) ->
                winston.error 'Error creating user', err
            )
        )
    else if process.argv[2] in ['--listusers', '-l']
        db.on('ready', ->
            User = db.models.User
            User.fetchAll().then((users) ->
                users = users.map((user) -> JSON.stringify(user.attributes))
                users.forEach((user) -> winston.info user)
                process.exit 0
            ).catch((err) ->
                winston.error 'Error listing users', err
            )
        )
else
    winston.info 'Initializing webserver'
    app = new Application(config, db)
