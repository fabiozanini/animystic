var chokidar = require('chokidar');
var exec = require('child_process').exec;

var browserify = './node_modules/browserify/bin/cmd.js'


function rebundle() {
  // bundle JS app
  console.log('Browserify COFFEE -> JS');
  exec(browserify+' coffee/*.coffee -t coffeeify -o build/app.js');

  // include CSS
  console.log('SASS -> CSS');
  exec('sass --sourcemap=none --scss style/app.sass build/app.css');

  // copy HTML
  console.log('Copy HTML');
  exec('cp html/index.html build/index.html');
}

// Watch and recompile
chokidar.watch(['coffee', 'html', 'style'], {ignored: /[\/\\]\./})
    .on('all', function(event, path) {

  console.log(event+': '+path)
  rebundle();
});

// Start web server
var connect = require('connect');
var serveStatic = require('serve-static');
(function serve() {
  var port = 3000;
  console.log("Starting web server at http://localhost:3000 ...")
  connect().use(serveStatic(__dirname+'/build')).listen(port);
})();
