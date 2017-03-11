find _site -name "*.html" -print0 | xargs -0 bin/katex.js
firebase deploy
