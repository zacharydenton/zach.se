---
title: A Better Way to Use Google Translate
excerpt: A command-line interface to Google Translate.
---

Google Translate is an invaluable tool for anyone who lives in a world
where multiple languages are spoken. No machine translation system is
perfect, but the one Google has created is one of the best --- and it's
constantly improving.

Typically, however, this artifact of power is accessed through a web
interface. The reason I don't like this is because it's slow. You have
to navigate to [Google Translate][], select the input language, select
the target language, type in your text, and then click "Translate". But
that's not good enough for you, is it? You want to translate
`das ist gut, ja?` and receive `this is good, yes?`!

To that end I have written a Python script which uses the Google
Translate API to translate its input into a language of your choice. It
automatically detects the input language and can translate into any
language supported by Google Translate (over ~~9000~~ 50 at the time of
writing). The script translates into English by default, but you can
easily change this with the `-t` (`--target`) argument --- allow me to
demonstrate.

Examples
--------

### Translate to English:

    $ translate Hola! ¿Habla usted español?
    Hello! Do you speak Spanish?

### Translate to Swedish:

    $ translate -t sv Hello! Do you speak Spanish?
    Hej! Talar du spanska?

### Translate to Swedish, by piping `fortune` to `translate`:

    $ fortune -s | translate -t sv
    <james> men, då jag använde en Atari, var jag mer sannolikt att vinna på lotteri i tio länder samtidigt, än att få snabbare X

Installation
------------

To install this script, just [save it][] as translate, make it
executable, and place it on your PATH. It's written in Python, so you
will need Python installed to run it. In addition, you will need the
modules json (included in version 2.6 onwards) and argparse (included in
version 2.7 onwards).

~~~~ {.python}
#!/usr/bin/env python
import sys
import json
import urllib
import urllib2
import argparse

def translate(target, text):
    api = "https://www.googleapis.com/language/translate/v2?"
    api_key = "AIzaSyBgBlJCogk_1Hd_7WaLQgLVbQss0_dvNUc"
    parameters = urllib.urlencode({
        'target': target,
        'key': api_key,
        'q': text
    })

    response = urllib2.urlopen(api + parameters)
    translations = json.loads(response.read())

    translated_text = translations['data']['translations'][0]['translatedText']
    return translated_text.encode('utf-8')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--target', default="en", \
                        help="the language to translate into (default: en)")
    parser.add_argument('text', nargs='*', help="the text to translate")
    args = parser.parse_args()

    if args.text:
        text = ' '.join(args.text)
    else:
        text = sys.stdin.read()
    
    print translate(args.target, text)

if __name__ == "__main__":
    main()
~~~~

  [Google Translate]: http://translate.google.com/ "Google Translate"
  [save it]: https://gist.github.com/gists/736436/download
    "Download the script"
