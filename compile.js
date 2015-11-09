var chokidar = require('chokidar');
var exec = require('child_process').exec;

var browserify = './node_modules/browserify/bin/cmd.js'


function rebundle() {
  // bundle JS app
  exec(browserify+' coffee/*.coffee -t coffeeify -o build/app.js');

  // include CSS
  exec('sass --sourcemap=none --scss style/app.sass build/app.css');
}

// Watch and recompile
chokidar.watch('.', {ignored: [/[\/\\]\./,
                              'node_modules',
                              'build']})
    .on('all', function(event, path) {

  rebundle();
});

// Start web server
var connect = require('connect');
var serveStatic = require('serve-static');
connect().use(serveStatic(__dirname+'/build')).listen(3000);
