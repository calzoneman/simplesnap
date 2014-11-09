var assert = require('assert');
var path = require('path');
var spawn = require('child_process').spawn;

var Configuration = require('../lib/configuration');
var Database = require('../lib/db/database');
var Application = require('../lib/web/application');

var config, db, app;

function runTest(opts, cb) {
    var method = opts.method.toUpperCase();
    var endpoint = opts.endpoint;
    var user_key = opts.user_key || null;
    var file = opts.file;
    var filekey = opts.filekey || 'image';
    var body = opts.body || {};

    var args = ['-X', method, 'http://localhost:5000' + endpoint];
    if (user_key) {
        args.push('-H');
        args.push('x-simplesnap-auth: ' + user_key);
    }

    if (file) {
        args.push('-F');
        args.push(filekey + '=@' + file);
    }

    for (key in body) {
        args.push('-F');
        args.push(key + '=' + body[key]);
    }

    var curl = spawn('curl', args);
    var data = '';
    curl.stdout.on('data', function (chunk) {
        data += chunk;
    });

    curl.stdout.on('close', function (code) {
        cb(code, data);
    });
}

(function () {
    config = new Configuration();
    config.db.connection.filename = path.join(__dirname, '..', 'test.sqlite');
    db = new Database(config.db);
    app = new Application(config, db);
})();

function wrap(cb) {
    return function (done) {
        db.addUser().then(function (user) { cb(user.get('key'), done); });
    };
}

beforeEach(function (done) {
    if (db.ready) return done();
    db.once('ready', done);
});

describe('/upload', function () {
    it('should return an error if the request has no file with key image', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            file: path.join(__dirname, 'test.png'),
            filekey: 'wrong'
        }, function (code, data) {
            data = JSON.parse(data);
            assert.equal(data.error, 'Expected image in request body');
            done();
        });
    }));
});
