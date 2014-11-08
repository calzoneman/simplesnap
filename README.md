simplesnap
==========

## What is it?

Simplesnap is a node.js application that allows you to host your own image upload service.  It features an embedded webserver that accepts `POST` and `PUT` requests to upload images, renames the images to a short hashed string, and serves the images.  Uploads may include an expiration field, to indicate that after a certain time the image will be deleted.  Image records and API keys are stored in a database (sqlite3 by default, but can use MySQL and Postgres).  Bash scripts are provided for uploading and managing images.  It does **not** have a human-facing interface for uploads or image management.

## Why?

There are already a plethora of image hosts out there, so why did I write my own?

  * I wanted a service that's simple.  I don't want to deal with OAuth and complicated APIs, I just want a service that I can `POST` an image to.
  * I wanted a service that doesn't re-encode images.  Imgur is especially bad about re-encoding large images with lossy formats.  With simplesnap, I can mandate my own file size limits and preserve the origina image format.
  * I wanted a service with easy expiration management.  I often take screenshots to share a quick look at something to a friend.  I don't want these images to be floating around the internet forever, nor do I want to be tasked with remembering to delete them.  With simlpesnap, I can choose an appropriate expiration and forget about it.
  * I wanted control of my own images.  I know exactly what happens when I'm uploading an image to simplesnap

## How do I use it?

You will need Linux and node.js.  If you plan to run the server on Debian or Ubuntu, install node.js from source or [from the NodeSource repositories](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager) to ensure you have a version of node that's not several years old.  In addition, you must have a C compiler installed to build some of the dependencies.

### Installation

  1. Clone the repository (`git clone https://github.com/calzoneman/simplesnap`)
  2. Change to the `simplesnap` directory and run `npm install`
  3. Copy `config.template.js` to `config.js` and make any modifications you would like to the configuration

### Using MySQL/MariaDB or Postgres instead of SQLite3

Simplesnap uses `knex`, which abstracts the database logic from the underlying database driver.  If you wish to use MySQL/MariaDB or Postgres instead of SQLite3, edit the configuration in `config.js` accordingly and install the appropriate node driver:

```
$ npm install mysql
$ npm install pg
```
