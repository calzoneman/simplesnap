module.exports = (bookshelf) ->
    Image = bookshelf.Model.extend({
        tableName: 'images',

        initialize: ->
            @on('creating', => @set('created_at', new Date()))
    }, {
        owner: ->
            return this.belongsTo(User, 'user_key')
    })

    User = bookshelf.Model.extend({
        tableName: 'users',

        initialize: ->
            @on('creating', => @set('created_at', new Date()))
    }, {
        images: ->
            return this.hasMany(Image, 'user_key')
    })

    return {
        Image: Image
        User: User
    }
