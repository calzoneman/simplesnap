winston = require 'winston'

Configuration = require './configuration'
Database = require './db/database'

config = new Configuration()

db = new Database(config.getDatabaseConfiguration())
