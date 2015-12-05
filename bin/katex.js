#!/usr/bin/env node
var fs = require('fs');
var katex = require('/home/zach/src/katex/');
var cheerio = require('cheerio');
var input = '';

function render(html) {
  var $ = cheerio.load(html);
  $('.math').each(function() {
    var $el = $(this);
    if ($el.children().length == 0) {
      var content = $el.text();
      var math = katex.renderToString(content, {displayMode: $el.is('.display')});
      $el.html(math);
    }
  });
  return $.html();
}

if (process.argv.length > 2) {
  process.argv.slice(2).forEach(function(path) {
    var html = fs.readFileSync(path);
    var processed = render(html);
    fs.writeFileSync(path, processed);
  });
} else {
  process.stdin.on('data', function(chunk) {
    input += chunk;
  });

  process.stdin.on('end', function() {
    console.log(render(input));
  });
}
