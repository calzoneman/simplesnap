var path = require('path');

/*
 * This file specifies overrides to the default configuration.
 * The values in this template file represent the default values.
 * To customize your configuration, copy this file to config.js
 * and edit it to your liking.
 */

module.exports = function (config) {
    /*
     * Database driver configuration. See http://knexjs.org/#Installation-client
     * By default, uses sqlite3.  In principle, the abstraction offered by knex
     * means simplesnap would work with MySQL or Postgres as well.
     */
    config.db = {
        client: 'sqlite3',
        connection: {
            filename: path.resolve(__dirname, 'snap.sqlite')
        }
    };

    /*
     * Map of allowed mime types to the associated file extension
     */
    config.allowedMimeTypes = {
        'image/bmp': 'bmp',
        'image/gif': 'gif',
        'image/jpeg': 'jpg',
        'image/png': 'png',
        'image/webp': 'webp',
        'image/svg+xml': 'svg',
        'video/webm': 'webm'
    };

    /*
     * Maximum allowed filesize (bytes)
     */
    config.maxFileSize = 8 * 1024 * 1024; // 8 MB

    /*
     * Directory to temporarily store uploaded files in while they are being processed
     */
    config.uploadDir = path.resolve(__dirname, 'uploads');

    /*
     * Directory to store processed image files in
     */
    config.storageDir = path.resolve(__dirname, 'im');

    /*
     * Base path for URLs.  For example, with a base path of /im/, the resulting URL is
     * http://hostname/im/(image filename)
     */
    config.basePath = '/';

    /*
     * Whether or not to allow anonymous uploads
     * (uploads without an x-simplesnap-auth header)
     */
    config.allowAnonymousUploads = false;

    /*
     * Name for the authorization header
     */
    config.authHeader = 'x-simplesnap-auth';

    /*
     * Maximum length of time a user can specify before an image expires.
     * Set to 0 to allow images that don't expire
     */
    config.expirationLimit = 30 * 24 * 60 * 60 * 1000

    /*
     * Interval (in milliseconds) at which to run the task that deletes expired images
     */
    config.deleteExpiredInterval = 10 * 60 * 1000 // 10 minutes

    /*
     * List of pairs [host, port] to bind the webserver to.
     * See http://nodejs.org/api/http.html#http_server_listen_port_hostname_backlog_callback
     */
    config.bindAddresses = [ ['', 5000] ];
};
