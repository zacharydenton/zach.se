--- 
title: How to Convert Your Music Library to MP3 on Linux
excerpt: A shell script which converts a music collection to MP3.
---

I have a fairly large music collection consisting of both
[FLAC](http://en.wikipedia.org/wiki/Free_Lossless_Audio_Codec "FLAC")
and MP3 files. This collection is far too large to fit on any of my
mobile devices without first being compressed. However, due to its size,
it would be tedious to manually add each album to a typical GUI
conversion tool. Therefore, I wrote a script which converts a music
collection consisting of both FLAC and MP3 to MP3 with a single command.
Files already in MP3 format are not transcoded; files in FLAC format are
converted using the settings of your choice (default: VBR V0).

To use the script, save it as compressor.sh and invoke it like this:

~~~~ {.console}
$ ./compressor.sh source_dir output_dir
~~~~

where `source_dir` is the path to your music collection and `output_dir`
is the directory in which you would like the resultant MP3 files to be
placed.

Without further ado, here is the script:

```bash
#!/usr/bin/env bash
# converts all .flac files to .mp3 and copies them to the
# OUT directory; copies all .mp3 files to the OUT directory.

LAMEOPTS="-V0 --quiet"

if [ "$#" -ne 2 ]
then
echo "usage: $0 MUSIC_DIR OUTPUT_DIR"
exit 1
fi

IN=$1
if [ ! -d "$IN" ]
then
echo "$IN is not a directory"
exit 1
fi

OUT=$2
if [ ! -d "$OUT" ]
then
mkdir "$OUT"
fi

# first, find all .mp3s and copy them to the OUT dir
# unless they are already there
find "$IN" -iname "*.mp3" | while read mp3;
do
OF=`echo "$mp3" | sed s,"$IN","$OUT\/",g`
dir=`dirname "$OF"`
if [ ! -d "$dir" ]
then
mkdir -p "$dir"
fi
if [ ! -e "$OF" ]
then
echo "copying $mp3 to $OF"
cp "$mp3" "$OF"
fi
done

# now, find all .flacs and convert them to .mp3
# unless they have already been converted
find "$IN" -iname "*.flac" | while read flac;
do
OF=`echo "$flac" | sed s/\.flac/\.mp3/g | sed s,"$IN","$OUT\/",g`
dir=`dirname "$OF"`
if [ ! -d "$dir" ]
then
mkdir -p "$dir"
fi
if [ ! -e "$OF" ]
then
# retrieve ID3 tags
ARTIST=`metaflac "$flac" --show-tag=ARTIST | sed s/.*=//g`
TITLE=`metaflac "$flac" --show-tag=TITLE | sed s/.*=//g`
ALBUM=`metaflac "$flac" --show-tag=ALBUM | sed s/.*=//g`
GENRE=`metaflac "$flac" --show-tag=GENRE | sed s/.*=//g`
TRACKNUMBER=`metaflac "$flac" --show-tag=TRACKNUMBER | sed s/.*=//g`
DATE=`metaflac "$flac" --show-tag=DATE | sed s/.*=//g`

# convert to MP3, preserving ID3 tags
echo "encoding $flac to $OF"
flac -c -dF --silent "$flac" | lame $LAMEOPTS \
--add-id3v2 --pad-id3v2 --ignore-tag-errors --tt "$TITLE" --tn "${TRACKNUMBER:-0}" --ta "$ARTIST" --tl "$ALBUM" --ty "$DATE" --tg "${GENRE:-12}" \
- "$OF"
fi
done
```




