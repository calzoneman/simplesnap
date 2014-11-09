Promise = require 'bluebird'

TABLES =
    images: (t) ->
        t.increments('id').primary()
        t.string('filename', 20).unique()
        t.string('user_key').references('users.key').onDelete('set null').index()
        t.dateTime('expires').index()
        t.timestamp('created_at')
    users: (t) ->
        t.increments('id').primary()
        t.string('key', 24).unique()
        t.timestamp('created_at')

module.exports = (knex) ->
    Promise.all(Object.keys(TABLES).map (table) ->
        knex.schema.hasTable(table).then (exists) ->
            if !exists
                console.log 'Creating table %s', table
                knex.schema.createTable(table, TABLES[table])
            else
                return true
    )
