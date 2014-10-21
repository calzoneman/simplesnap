var config = {};


//Bug in http module?: despite specifying "::", it'll still listeon on ipv4 localhost
//config.useIPv6 = true;
//config.useIPv4 = true;

//Self explanatory
//config.maxSize = 8*1024*1024;

//port used when none is specified
//config.defaultPort = 5000; 

//X-Forwarded-For is trusted by these
//config.trustProxies = ['loopback'];

//array of host,port[optional] objects. Defaults to listening on everything.
//config.listenPairs = [{host:'127.0.0.1'}];

//config.imagePath = 'im';

module.exports = config;
//vim: ts=4:sw=4
