---
title: Export Facebook Contacts with Android
excerpt: How to use a rooted Android phone to export your Facebook address book.
---

If you have a rooted Android phone, you have full control over your
device --- and unrestricted access to the data it contains. In this post,
I'm going to show you how you can use your rooted Android device to do
something that [the average person can't
do](http://techcrunch.com/2011/02/22/google-android-facebook-contacts/):
namely, export your contacts from the Facebook app on Android.

1. Get the contacts database
----------------------------

It turns out that the Facebook app stores your contacts in an SQLite
database located on the filesystem at
`/data/data/com.facebook.katana/databases/fb.db`. In order to use this
database, we need to copy it to a computer. Since Android doesn't
provide access to the internal storage via USB, I first copied the
database to my SD card using a root file browser, and then copied it to
my computer via USB.

2. Examine the contacts database
--------------------------------

Now that you have the database on your local machine, you can analyze it
and determine its structure. Begin by opening it up with the SQLite
client:

    $ sqlite3 /path/to/fb.db

Now it's just the standard procedure when dealing with an unknown
database:

### 2.1 List the tables

    sqlite> .tables
    albums                    friends                   page_search_results
    android_metadata          friends_data              perf_sessions
    cache                     key_value                 photos
    chatconversations         mailbox_messages          search_results
    chatmessages              mailbox_messages_display  stream_photos
    connections               mailbox_profiles          user_statuses
    default_page_images       mailbox_threads           user_values
    events                    notifications

### 2.2 Determine which tables contain the data you're looking for

The table's name is often a good indicator of its contents. In this
case, the `friends` table (technically, it's a
[view](http://www.sqlite.org/lang_createview.html)) contains all the
data we need.

### 2.3 Determine which columns to extract

Here's the structure of the `friends` view:

    sqlite> .schema friends
    CREATE VIEW friends AS SELECT connections._id AS _id, connections.user_id AS user_id, connections.display_name AS display_name, connections.connection_type AS connection_type, connections.user_image_url AS user_image_url, connections.user_image AS user_image, connections.hash AS hash, friends_data.first_name AS first_name, friends_data.last_name AS last_name, friends_data.cell AS cell, friends_data.other AS other, friends_data.email AS email, friends_data.birthday_month AS birthday_month, friends_data.birthday_day AS birthday_day, friends_data.birthday_year AS birthday_year FROM connections LEFT OUTER JOIN friends_data ON connections.user_id=friends_data.user_id WHERE connections.connection_type=0;

In this case, the important columns are:

-   `display_name`
-   `user_image_url`
-   `first_name`
-   `last_name`
-   `cell`
-   `other`
-   `email`
-   `birthday_month`
-   `birthday_day`
-   `birthday_year`

At this point, the hard part is over and it's just a matter of
extracting the data from the database.

3. Export the data
------------------

### 3.1 The vCard format

Now that we know exactly which data we need, we can export it from the
database into a useful format. The most useful format for contact data
appears to be [vCard](https://en.wikipedia.org/wiki/VCard), which is
almost universally supported in communication apps. I won't go into the
details of the [vCard
specification](https://tools.ietf.org/html/rfc6350), but here's an
example of what we're trying to generate:

    BEGIN:VCARD
    VERSION:3.0
    N:Feynman;Richard;;;
    FN:Richard Feynman
    TEL;TYPE=HOME:+72973525698
    EMAIL;TYPE=PREF:rfeynman@princeton.edu
    BDAY:1918-5-11
    REV:2012-01-08T18:36:35.814661
    END:VCARD

    BEGIN:VCARD
    VERSION:3.0
    N:Planck;Max;;;
    FN:Max Planck
    TEL;TYPE=CELL:+66260695729
    EMAIL;TYPE=PREF:planck@berlin.de
    BDAY:1858-4-23
    REV:2012-01-08T18:36:36.043204
    END:VCARD

Notice that multiple contacts can exist in the same file.

### 3.2 A script to generate the vCard

I've written a Python script to generate a vCard from the `fb.db`:

~~~~ {.python}
#!/usr/bin/env python
import sys
import base64
import codecs
import sqlite3
import urllib2
import argparse
import datetime

def parse_database(database):
    conn = sqlite3.connect(database)
    conn.row_factory=sqlite3.Row
    c = conn.cursor()
    fields = 'display_name, user_image_url, first_name, ' +\
             'last_name, cell, other, email, birthday_month, ' +\
             'birthday_day, birthday_year'
    c.execute('select %s from friends' % fields)
    return [row for row in c]

def generate_vcard(contact, photos=False):
    card = "BEGIN:VCARD\nVERSION:3.0\n"
    card += "N:%s;%s;;;\n" % (contact['last_name'], contact['first_name'])
    card += "FN:%s\n" % contact['display_name']

    if contact['cell']:
        card += 'TEL;TYPE=CELL:%s\n' % contact['cell']

    if contact['other']:
        card += 'TEL;TYPE=HOME:%s\n' % contact['other']

    if contact['email']:
        card += "EMAIL;TYPE=PREF:%s\n" % contact['email']

    birthday = "-".join([str(f) for f in [contact['birthday_year'],
                                          contact['birthday_month'],
                                          contact['birthday_day']]
                         if f != -1])
    if birthday:
        if birthday.count('-') == 1: birthday = "1900-" + birthday # default year
        card += "BDAY:%s\n" % birthday

    if photos and contact['user_image_url']:
        try:
            photo = urllib2.urlopen(contact['user_image_url']).read()
            card += "PHOTO;ENCODING=B;TYPE=JPEG:%s\n" %\
                    base64.b64encode(photo)
        except:
            pass


    card += "REV:%s\nEND:VCARD\n" % datetime.datetime.now().isoformat()
    return card

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('database', help="path to facebook database", default="fb.db", nargs='?')
    parser.add_argument('vcard', help="file to write contacts to", default="fbcontacts.vcf", nargs='?')
    parser.add_argument('--photos', action="store_true", help="download profile pictures")
    args = parser.parse_args()

    with codecs.open(args.vcard, 'w', 'utf-8') as vcard:
        contacts = parse_database(args.database)
        for i, contact in enumerate(contacts):
            sys.stderr.write("\rexporting contact %s of %s" % (i+1, len(contacts)))
            card = generate_vcard(contact, args.photos)
            print >> vcard, card
            sys.stderr.flush()
        sys.stderr.write("\n")

if __name__ == "__main__": main()
~~~~

It just goes through each row, grabs the relevant data, and writes it
out in vCard format.

To use the script, just run `python fbcontacts.py /path/to/fb.db`.
You'll end up with all of your contacts in a vCard file, complete with
email addresses, phone numbers, birthdays, and (if you specify the
`--photos` flag) profile pictures.

Conclusion
----------

Restrictions don't apply to those with rooted phones and a bit of
curiosity.
