bookshelf = require 'bookshelf'
knex = require 'knex'
winston = require 'winston'
uuid = require 'uuid'
EventEmitter = require('events').EventEmitter

buildSchema = require './schema'

class Database extends EventEmitter
    constructor: (@config) ->
        @knex = knex(@config)
        @bookshelf = bookshelf(@knex)
        @ready = false
        @models = require('./models')(@bookshelf)

        if @knex.client == 'sqlite3'
            @knex.raw('PRAGMA foreign_keys = ON;')

        buildSchema(@knex).then =>
            winston.info 'Database initialized'
            @ready = true
            @emit 'ready'
        .catch (err) ->
            winston.error 'Database initialization failed', err, {}

    genAPIKey: () ->
        key = new Buffer(16)
        uuid.v4(null, key)
        return key.toString('base64')

    genFileHash: (name) ->
        alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        hash = (str) ->
            h = 0
            for i of str
                x = str.charCodeAt(i)
                h = x + (h << 6) + (h << 16) - h
            return h & 0x7fffffff

        ts = Date.now()
        ts = (ts << 1) + (hash(name) % ts)
        ts = Math.abs(ts)

        code = ''
        while ts > 0
            code += alphabet[ts % alphabet.length]
            ts = Math.floor(ts / alphabet.length)

        return code


    addUser: () ->
        if not @ready
            throw new Error('Database has not been initialized yet')

        User = @models.User
        return User.forge(key: @genAPIKey()).save().tap((user) => @emit 'newuser', user.attributes)

    addImage: (file, uploader_key = null) ->
        data =
            filename: [@genFileHash(file.filename), file.extension].join('.')
            expires: Date.now() + file.expiration

        if uploader_key
            data.user_key = uploader_key

        Image = @models.Image
        return Image.forge(data).save().tap((image) => @emit 'newimage', image.attributes)


module.exports = Database
