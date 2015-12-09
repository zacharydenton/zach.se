find _site -name "*.html" -print0 | xargs -0 bin/katex.js
rsync -av _site/ /srv/http/zach.se/public/
