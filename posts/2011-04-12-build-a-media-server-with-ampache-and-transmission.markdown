---
title: Build a Media Server With Ampache and Transmission
excerpt: A guide to building the ultimate music server using open source software.
---

This guide will teach you how to unleash your music collection. Access
it from anywhere with an internet connection -- on your laptop, your phone,
at work, or on a plane.

This guide has three parts. Part one tells you how to build a server for 
less than $300. Part two discusses how to build a music collection. 
Part three discusses how to stream that collection across the internet.
<!--more-->

If you already have a computer that is connected to the Internet 24/7,
you can skip part one.

Part One: Building a Server
---------------------------
We will need a computer to use as the server. You have three options
here:

1. Re-use an old computer. The cheapest option.
2. Purchase a new computer. The easiest option.
3. Build a new computer. The educational option.
4. Purchase a <abbr title="Virtual private server">VPS</abbr>. Potentially the best option, with a few caveats ([more details below](#vps-note)).

If you chose option 3, read the following section. Otherwise you can
skip past it.

### Building a new computer ###
The first thing to do when building a new computer is to come up with a
parts list. It turns out that there are only six things you need to build 
a computer:

* CPU (aka processor)
* Motherboard
* RAM (aka memory)
* Storage drive(s)
* Power supply
* Case

Seasoned builders will be quick to point that there are a plethora of
additional parts that can be used to build a computer. Expert builders will
be even quicker to point out that you don't even need a case
or storage drives. For the purposes of this guide, however, I will focus
on the six aforementioned parts. What follows is a list of the six parts
I used to build my media server. They will most likely be out of date by
the time you read this -- just use them as an example.

#### CPU: AMD Athlon II X2 250 ($60.99) ####
You don't need a super-powerful processor in your server. That said,
this processor packs an astonishing punch at 60 bucks.

#### Motherboard: Gigabyte GA-MA74GM-S2 740G ($54.99) ####
I'm really pleased with this motherboard. It's very small (Micro ATX),
yet it comes with a ton of features like onboard video, gigabit
ethernet, sound, and the ability to upgrade to a discrete graphics card
if desired. 

If you use this motherboard (or similar), your media server
will be able to perform double-duty as a media center if you hook it up
to your TV. Expect to see another guide explaining how to do this in the
future.

#### RAM: A-DATA 2GB DDR2-800 ($32.99) ####
Just some basic, cheap DDR2 RAM. Works well (did I mention it was
cheap?).

#### Storage drive: Samsung Spinpoint F4 2TB 5400 RPM ($79.99) ####
You're going to want a large drive in your media server to store your
music collection. 2TB for 80 bucks is just an incredible deal. Less than three
years ago I paid the same price for 10% of that.

#### Power supply: Logisys 575W ($24.99) ####
Normally I use high-end power supplies when building computers, so I was
a bit wary of using this $25 power supply. It was substantially lighter
than I am used to (heftier power supplies are typically higher-quality),
but so far it has performed admirably.

#### Case: Apex TX-381-C Micro ATX Tower ($29.99) ####
It's a solid case. Very inexpensive. Somewhat loud.

That's a grand total of around 280 bucks for a great server. Today you can 
probably get an even better machine for the same price or less.

Once you have all of the parts, you will need to put them together.
Check out [How To Assemble A Desktop PC][], a great wikibook teaching
you how to do that.

  [How To Assemble A Desktop PC]: http://en.wikibooks.org/wiki/How_To_Assemble_A_Desktop_PC

### Setting up the server ###
Now that you have a machine to use as your media server, you will need
to install Linux on it. The version (or "distro") I recommend is Ubuntu
Server Edition. Take a look at
the [Ubuntu Server Guide](https://help.ubuntu.com/10.10/serverguide/C/index.html). 
which will teach you everything you need to know. 

You're going to want to set up SSH access to your machine so that you
can manage it remotely. You can find the details in the 
[OpenSSH section of the Ubuntu Server Guide](https://help.ubuntu.com/10.10/serverguide/C/openssh-server.html). 

The final thing you need to do is to hook your new server up to the
Internet. For streaming 320kbps music files, I recommend having a minimum
upload bandwidth of around 384kbps (50KB/s). That's what I used to have,
and occasionally I had to reduce the streaming rate to 192kbps to
eliminate stuttering. Miraculously my ISP increased my upload bandwidth to around 1mbps, 
for free (as far as I know). That's more than enough for streaming music.

<h3 id="vps-note">A note on VPSs</h3>
If you opt to use a VPS, you don't have to worry about setting up a
Linux server with a 24/7 high speed internet connection. What you do
need to worry about is violating your hosting provider's Terms of
Service. They may not appreciate you downloading and streaming music on
their servers.

The other thing is that you likely won't have unlimited disk space, even
if you do have "Unlimited Disk Space!". I would think twice before
uploading a 400GB FLAC collection to a VPS.

If you can deal with these two conditions, then using your VPS as a media
server is probably the best way to go. You get an extremely fast
connection and you don't have to worry as much about maintaining the
server.

Part Two: Building a music collection
-------------------------------------
What good is a music server without any music? That's a problem that
this section of the guide intends to solve. There are a lot of ways to
get music these days: iTunes, purchasing directly from the artist,
BitTorrent, and even purchasing from a store. For simplicity, I'm just
going to focus on BitTorrent. If you don't know what
BitTorrent is, you may want to read [this introduction](http://www.bittorrent.org/introduction.html) first.

This section of the guide will teach you how to access and use the best
music repositories in the world (for free).

### Installing the BitTorrent client ###
You may be familiar with Transmission -- it's an excellent, easy-to-use
BitTorrent client for Windows, Mac, and Linux. Transmission can also run
in the background, as a daemon. This is called `transmission-daemon`.
`transmission-daemon` comes with a beautiful web interface which you will
be using to manage your torrents from anywhere in the world.

To install `transmission-daemon` on Ubuntu, ssh into your server and type the following:

``` console
$ sudo aptitude install transmission-daemon
```

First we make sure that `transmission-daemon` is not running:

``` console
$ sudo /etc/init.d/transmission-daemon stop
```

Now you want to configure `transmission-daemon`, so do:

``` console
$ sudo $EDITOR /etc/transmission-daemon/settings.json
```

You want to make the following changes:

``` js
"rpc-whitelist-enabled": false,
"rpc-username": "your-username",
"rpc-password": "your-password",
```

This allows you to access `transmission-daemon` remotely, as long
as you specify the correct username and password.

Finally, we restart `transmission-daemon`:

``` console
$ sudo /etc/init.d/transmission-daemon start
```

Now you can log in to the `transmission-daemon` web interface by pointing your web browser to
http://your-server:9091/. Once you've logged in, you should see a nice
interface where you can manage torrents and edit preferences. This is
how you'll be interacting with `transmission-daemon` most of the time. 

What we need now is some torrents to download!

### Finding music for your collection ###
I usually find new music based on recommendations from friends or
Last.fm. Last.fm is a service which monitors your listening habits and
then provides recommendations based on that data. It's pretty cool, and
it makes it easier to answer "So, what kind of music do you like?"
with something other than "Oh, I listen to a little bit of everything.".

Once you have some candidates for adding to your collection, you need to
actually get your hands on the files. To do this, we use a
BitTorrent search engine. The three that I use are (ranked from decent to
best):

* The Pirate Bay
* Demonoid
* What.CD

#### The Pirate Bay ####
Most BitTorrent users will be familiar with The Pirate Bay. It's one of
the largest BitTorrent sites and certainly the most infamous. They offer
a fair amount of music, probably enough for the casual user. There are
no real quality standards here so you may have to search a bit before
finding the good stuff. The Pirate Bay does not require registration.

#### Demonoid ####
Demonoid is similar to The Pirate Bay in that it offers a wide range of
content. I often find that if something isn't on TPB, it's on Demonoid
(and vice versa). Demonoid requires registration, but it's not difficult
to get in.

#### What.CD ####
What.CD is the holy grail for music enthusiasts. It is indisputably the
greatest music collection ever assembled. If you're lucky enough to get
in, you will have access to pretty much every release of every album in
any format you could want. They maintain their high quality by
maintaining a high quality userbase, so if you want to get in you have
two options: get an invite or pass an interview.

### A brief digression on formats ###
There are two kinds of music formats: lossy and lossless. 

MP3, AAC, and OGG are all lossy formats, meaning that they discard some of the audio
data in order to achieve smaller file sizes. Lossy formats are prevalent
on public trackers like The Pirate Bay.

FLAC is a lossless format, meaning that it preserves all of the original
audio data. As you build your music collection, you will learn more and
more about FLAC. My collection consists solely of FLACs.
One cool thing about FLAC that relates to this guide is that you can convert it to a
lossy format on-the-fly for streaming over the internet -- useful if you
have a slow connection.

Part three: Serving your music collection over the Internet
-----------------------------------------------------------
To stream your music over the Internet we will be using something called
Ampache. The name is a portmanteau of the words Amp (as in amplifier)
and Apache (the prominent web server).

Ampache provides a web interface to your music collection. You use the
interface to create playlists. The playlists can then be played in the
browser or opened in your favorite standalone media player. There are
also Ampache clients for Android and iPhone, so you can access your full
music collection on your phone. Additionally, Ampache can transcode your
music on-the-fly to any format (useful for streaming to devices with
slower internet connections).

### Installing Ampache ###
Ampache is included in the Ubuntu repositories. Just do:

``` console
$ sudo aptitude install ampache mysql-server
```

And the required programs will be installed for you. When asked which
web server to configure automatically, select apache2. When asked to
restart the web server, select "Yes". Choose the root password for your
MySQL server and remember it.

At this point, try navigating to http://your-server/ampache/. If the
page is not found, do the following:

``` console
$ sudo $EDITOR /etc/apache2/apache2.conf
```

Add the following to the bottom of that file:

```apache
Include /etc/ampache/ampache.conf
```

Restart the web server:

``` console
$ sudo /etc/init.d/apache2 restart
```

Now, open http://your-server/ampache/ in a web browser. You will see a
webpage entitled 'Ampache Installation'. Click on 'Start configuration'
near the bottom of the page.

On the next page, enter the MySQL root password in the 'MySQL
Administrative Password' box. Then click 'Insert Database'.

On this page, type 'root' into the 'MySQL Username' box. The 'MySQL
username' is the MySQL root password you entered on the previous page.
Click 'Write Config' and you will be prompted to download an
`ampache.cfg.php` file. Save this file to your local machine. 

### Configuring Ampache ###
Make the following changes to `ampache.cfg.php`:

``` yaml
xml_rpc: "true"
allow_zip_download: "true"
transcode_m4a: "false"
```

If you would like to transcode your FLACs on-the-fly, make the following
change: 

``` yaml
transcode_flac: "true"
```

If you have multiple formats of each album (e.g. if you download albums in
MP3, OGG, AAC, and FLAC), each format will be indexed. To eliminate these
duplicates, you can opt to only index one of these formats. To only
index FLAC:
	
``` yaml
catalog_file_pattern: "flac"
```

When you've finished editing `ampache.cfg.php`, copy it to the
`/etc/ampache` directory on your server:

``` console
$ scp /path/to/ampache.cfg.php root@your-server:/etc/ampache/
```

Once `ampache.cfg.php` is in place on your server, click 'Check for
Config'. Both 'Ampache.cfg.php Exists' and 'Ampache.cfg.php Configured?'
should now say 'OK'. Click 'Continue to Step 3'.

Finally, setup the administrator account. Once you've filled out the
form, click 'Create Account'.

Login to your Ampache installation as the administrator. We will now
configure Ampache to scan your music collection.

On the menu at the left of the page, click the 'Admin' icon (looks like
a small server). Then click 'Add a Catalog'.

The catalog name can be anything you like. 'Path' should be set to to
the path of your music location. If you are using `transmission-daemon`
and would like all of its downloads to be indexed, use
`/var/lib/transmission-daemon/downloads/`. Then click 'Add Catalog'.

Once your music collection has been indexed, click 'Continue'. Now click
on the 'Preferences' icon in the menu on the left of the page.

If you have opted to transcode FLACs on-the-fly, click on 'Streaming' 
and set your 'Transcode Bitrate' to something more
reasonable, like 320. Click 'Update Preferences' and you're done.

### Using Ampache ###
Now you're ready to use Ampache. Using Ampache is basically a two-step
process. First you queue some music into a playlist. Then you open that
playlist in a media player which handles the streaming for you.

#### Queueing Music ####
Click on the "Home" icon in the menu on the left. Click on "Albums" to
view a list of your albums. If you click the green plus icon next to
any album title, it will be loaded into your playlist. You'll see the
tracks in the playlist view on the right side of the screen.

#### Opening the playlist ####
Now that you have some music in the playlist, click the "Play" icon
(looks like a broadcast tower) located above the playlist on the right
side of the screen. You will be prompted to download a playlist file.
Download it and open it with the media player of your choice -- Totem or
VLC for example. You should hear some music. Enjoy!

Conclusion
----------
Hopefully you now have enough information to build a killer media
server. I covered a lot of ground in this guide, so feel free to ask any
questions you may have.
