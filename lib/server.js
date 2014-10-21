var express = require('express'),
    app = express(),
    bodyParser =  require('body-parser'),
    compression =  require('compression'),
    url = require('url'),
    dns = require('dns'),
    ipaddr = require('ipaddr.js'),
    multiparty = require('multiparty'),
    mmmagic = require('mmmagic'),
    Magic = mmmagic.Magic,
    fs = require('fs'),
    path = require('path'),
    db = require('./database'),
    initialized = false,
    config = require('./srvconfig.js');

const IMAGE_EXT = {
    'image/bmp': 'bmp',
    'image/gif': 'gif',
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/svg': 'svg'
};
const MAX_BYTES = config.maxSize || 8 * 1024 * 1024;
const IMAGE_DIR = path.normalize(config.imagePath||"im");
const LISTEN_ANY = [
    {'host':'0.0.0.0','port':config.defaultPort||5000},
    {'host':'::','port':config.defaultPort||5000}
];
/**
 * Express middleware for parsing a file upload.
 * Includes a check for maximum upload size.
 * Relies on multiparty.
 */
function fileParser() {
    return function fparse(req, res, next) {
        if (['post', 'put'].indexOf(req.method.toLowerCase()) === -1) {
            return next();
        }

        var form = new multiparty.Form({
            autoFiles: true,
            uploadDir: IMAGE_DIR
        });

        form.on('progress', function (bytesReceived, bytesExpected) {
            if (bytesReceived > MAX_BYTES) {
                res.sendStatus(413);
                req.destroy();
            }
        });

        form.parse(req, function (err, fields, files) {
            if (err) {
                return next(err);
            }
            req.files = files;
            for (var key in fields) {
                req.body[key] = fields[key][0];
            }
            next();
        });
    };
}

/**
 * Produces a unique hash for use as a filename.
 * Uses the current timestamp and a hash of the filename to prevent the unlikely case
 * of two images being uploaded at the same millisecond.
 */
function fileHash(filename) {
    const c = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    function hash(str) {
        var h = 0;
        for (var i = 0; i < str.length; i++) {
            var x = str.charCodeAt(i);
            h = x + (h << 6) + (h << 16) - h;
        }
        return h & 0x7fffffff;
    }


    var ts = Date.now();
    ts = (ts << 1) + (hash(filename) % ts);
    ts = Math.abs(ts);

    var code = "";
    while (ts > 0) {
        code += c[ts % c.length];
        ts = Math.floor(ts / c.length);
    }

    return code;
}

/**
 * Returns an expiration timestamp based on a string such as "10m", "4h"
 */
function parseExpiration(text) {
    const ONE_MINUTE = 60 * 1000;
    const ONE_HOUR = 60 * ONE_MINUTE;
    const ONE_DAY = 24 * ONE_HOUR;

    if (typeof text !== "string") {
        return Date.now() + ONE_DAY;
    }

    var m = text.match(/(\d+)(d|m|h)/);
    if (!m) {
        return Date.now() + ONE_DAY;
    }

    var count = parseInt(m[1]);
    if (count <= 0) {
        count = 1;
    }

    switch (m[2]) {
        case 'd':
            return Date.now() + ONE_DAY * count;
        case 'h':
            return Date.now() + ONE_HOUR * count;
        case 'm':
            if (count < 10) {
                count = 10;
            }
            return Date.now() + ONE_MINUTE * count;
    }
}

/**
 * Handles a POST request to upload a file
 */
function uploadFile(req, res) {
    if (!req.files || !req.files.image || req.files.image.length === 0) {
        res.sendStatus(400);
        return;
    }

    var f = req.files.image[0],
        magic = new Magic(mmmagic.MAGIC_MIME_TYPE);

    var afterAuth = function () {
        magic.detectFile(f.path, function (err, mime) {
            f.mimetype = mime;
            if (!(mime in IMAGE_EXT)) {
                res.sendStatus(415);
            } else {
                f.expires = parseExpiration(req.body.expires);
                processFile(f, function (err, data) {
                    if (err) {
                        res.sendStatus(500);
                    } else {
                        res.jsonp(data);
                    }
                });
            }
        });
    };

    if (!req.cookies || !req.cookies.auth) {
        afterAuth();
    } else {
        db.findAccount({ auth: req.cookies.auth }, function (err, docs) {
            if (err) {
                res.status(400);
                res.jsonp({
                    error: "Authorization failed"
                });
                return;
            } else {
                f.uploader = docs[0].name;
                afterAuth();
            }
        });
    }
}

/**
 * Processes a file upload
 */
function processFile(f, cb) {
    var filename = f.originalFilename,
        hash = fileHash(filename),
        ext = IMAGE_EXT[f.mimetype],
        newpath = path.join(IMAGE_DIR, hash + '.' + ext);

    fs.rename(f.path, newpath, function (err) {
        if (err) {
            if (cb) {
                cb(err);
            }
            return;
        } else {
            f.path = newpath;
            var data = {
                filename: filename,
                path: f.path,
                uploader: f.uploader || 'anonymous',
                expires: f.expires
            };
            db.insertImage(data, function (err, doc) {
                if (err) {
                    cb(err, null);
                } else {
                    cb(null, data);
                }
            });
        }
    });
}

/**
 * Deletes an image file
 */
function deleteFile(doc) {
    var fn = path.normalize(doc.path);
    fs.unlink(fn, function (err) {
        if (err) {
            console.log('[ERROR] Failed to delete image file: ' + err);
        }
    });
}

/**
 * Serves an image
 */
function serveImage(req, res) {
    var ipath = url.parse(req.url).pathname.replace(/^\//,'');
    db.findImage({ path: ipath }, function (err, docs) {
        if (err || docs.length === 0) {
            console.log('[WARN] 404: ' + ipath);
            res.sendStatus(404);
        } else {
            res.sendFile(ipath, {
                root: './'
            });
            console.log('[INFO] Served ' + ipath);
        }
    });
}

function init() {
    if (initialized) {
        return;
    }

    if (!fs.existsSync(IMAGE_DIR)) {
        fs.mkdirSync(IMAGE_DIR);
    }

    app.use(bodyParser.urlencoded({extended:true}));
    app.use(bodyParser.json());
    app.use(compression());
    app.use(fileParser());
    app.post('/upload', uploadFile);
    app.get(/(\/[a-zA-z0-9]+\.(?:bmp|jpg|png|gif|webp|svg))/, serveImage);
    if (config.trustProxies){
        Array.isArray(config.trustProxies)
        app.set('trust proxy',Array.isArray(config.trustProxies)||['loopback']);
    }
    var pair,i,lp = (config.listenPairs || LISTEN_ANY),safe;
    for (i = 0;   i<lp.length; i++) {
        pair = lp[i];
        safe = {};
        if (ipaddr.isValid(pair.host)) {
            pair.ip = ipaddr.process(pair.host);
            safe[pair.ip.kind()] = pair.ip;
        } else {
            if (config.useIPv4) dns.lookup(pair.host,4,function(err,add,family) {
                if (err){
                    console.log('[ERROR] Could not resolve ipv4 address of' + pair.host + ': ' + err.code);
                } else {
                    pair.ip = ipaddr.process(add);
                    safe[pair.ip.kind()] = pair.ip;
                }
            });
            if (config.useIPv6) dns.lookup(pair.host,6,function(err,add,family) {
                if (err){
                    console.log('[ERROR] Could not resolve ipv6 address of' + pair.host + ': ' + err.code);
                } else {
                    pair.ip = ipaddr.process(add);
                    safe[pair.ip.kind()] = pair.ip;
                }
            });
        }
        if (config.useIPv6 && safe.ipv6 && (typeof config.useIPv6 !== 'undefined' && config.useIPv6 || true ) )
            app.listen(config.port || 5000,safe.ipv6);
        if (config.useIPv4 && safe.ipv4 && (typeof config.useIPv4 !== 'undefined' && config.useIPv4 || true ) )
            app.listen(config.port || 5000,safe.ipv4);
        
    }

    setInterval(function () {
        var filter = { expires: { $lt: Date.now() } };
        db.findImage(filter, function (err, docs) {
            if (err) {
                console.log('[ERROR] Failed to retrieve expired images: ' + err);
            } else {
                var i = 0;
                docs.forEach(function (doc) {
                    deleteFile(doc);
                    i++;
                });
                if (i>0) console.log('[INFO] Deleted ' + i + ' expired image files');
                db.deleteImage(filter, function (err, num) {
                    if (err) {
                        console.log('[ERROR] Failed to delete expired image records: ' + err);
                    } else {
                        if (i>0) console.log('[INFO] Deleted ' + num + ' image records');
                    }
                });
            }
        });
    }, 10 * 60 * 1000);

    initialized = true;
}

module.exports.init = init;
// vim: ts=4:sw=4
