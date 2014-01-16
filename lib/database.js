var path = require('path');

var Datastore = require('nedb'),
    accounts = new Datastore({ filename: path.join(__dirname, '..', 'accounts.db') }),
    images = new Datastore({ filename: path.join(__dirname, '..', 'images.db') });

accounts.loadDatabase();
images.loadDatabase();

exports.insertImage = function (data, cb) {
    images.insert(data, function (err, doc) {
        if (cb) {
            cb(err, doc);
        }
    });
};

exports.findImage = function (filter, cb) {
    images.find(filter, function (err, docs) {
        if (cb) {
            cb(err, docs);
        }
    });
};

exports.deleteImage = function (filter, cb) {
    images.remove(filter, { multi: true }, function (err, docs) {
        if (cb) {
            cb(err, docs);
        }
    });
};

exports.findAccount = function (filter, cb) {
    accounts.find(filter, function (err, docs) {
        if (cb) {
            cb(err, docs);
        }
    });
};
