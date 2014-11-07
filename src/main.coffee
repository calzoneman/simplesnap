winston = require 'winston'

Configuration = require './configuration'
Database = require './db/database'
Application = require './web/application'

config = new Configuration()
db = new Database(config.db)
app = new Application(config, db)
