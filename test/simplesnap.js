var assert = require('assert');
var fs = require('fs');
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
    var body = opts.body || {};

    var args = ['-X', method, 'http://localhost:5000' + endpoint];
    if (user_key) {
        args.push('-H');
        args.push('x-simplesnap-auth: ' + user_key);
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

    curl.stderr.on('data', function (chunk) {
        if (process.env.CURL_DEBUG) console.log(chunk.toString());
    });
}

(function () {
    config = new Configuration();
    config.db.connection.filename = path.resolve(__dirname, 'test_data', 'test.sqlite');
    config.storageDir = path.resolve(__dirname, 'test_data', 'im');
    config.uploadDir = path.resolve(__dirname, 'test_data', 'uploads');
    if (!fs.existsSync(config.uploadDir))
        fs.mkdirSync(config.uploadDir)
    if (!fs.existsSync(config.storageDir))
        fs.mkdirSync(config.storageDir)
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

after(function () {
    fs.unlinkSync(config.db.connection.filename);
});

describe('/upload', function () {
    it('should accept a valid upload with authorization', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png'),
                expiration: '10m'
            }
        }, function (code, data) {
            data = JSON.parse(data);
            assert(!data.error, 'Expected no error');
            assert(data.filename, 'Expected filename to be present');
            done();
        });
    }));

    it('should accept a valid upload with no authorization if allowAnonymousUploads is enabled', wrap(function (user_key, done) {
        config.allowAnonymousUploads = true;
        runTest({
            method: 'POST',
            endpoint: '/upload',
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png'),
                expiration: '10m'
            }
        }, function (code, data) {
            config.allowAnonymousUploads = false;
            data = JSON.parse(data);
            assert(!data.error, 'Expected no error');
            assert(data.filename, 'Expected filename to be present');
            done();
        });
    }));

    it('should reject an upload with no authorization if allowAnonymousUploads is disabled', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png'),
                expiration: '10m'
            }
        }, function (code, data) {
            data = JSON.parse(data);
            assert.equal(data.error, 'Missing x-simplesnap-auth header');
            done();
        });
    }));

    it('should reject an upload if the request has no file with key image', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            body: {
                lel: '@' + path.resolve(__dirname, 'test_data', 'image.png')
            }
        }, function (code, data) {
            data = JSON.parse(data);
            assert.equal(data.error, 'Expected image in request body');
            done();
        });
    }));

    it('should reject an upload with an invalid expiration', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png'),
                expiration: 'dummy'
            }
        }, function (code, data) {
            data = JSON.parse(data);
            assert.equal(data.error, 'Invalid expiration');
            done();
        });
    }));

    it('should reject an upload with no expiration', wrap(function (user_key, done) {
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png')
            }
        }, function (code, data) {
            data = JSON.parse(data);
            assert.equal(data.error, 'Expiration is required');
            done();
        });
    }));

    it('should accept an upload with no expiration if expirationLimit = 0', wrap(function (user_key, done) {
        config.expirationLimit = 0;
        runTest({
            method: 'POST',
            endpoint: '/upload',
            user_key: user_key,
            body: {
                image: '@' + path.resolve(__dirname, 'test_data', 'image.png'),
                expiration: '10m'
            }
        }, function (code, data) {
            config.expirationLimit = 30 * 24 * 60 * 60 * 1000;
            data = JSON.parse(data);
            assert(!data.error, 'Expected no error');
            assert(data.filename, 'Expected filename to be present');
            done();
        });
    }));
});
