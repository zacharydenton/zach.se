---
title: "Music Server Revisited: Streaming with sshfs and mp3fs"
excerpt: Access a remote music collection seamlessly with user-space filesystems.
---

A while back, I wrote about [streaming music with
Ampache](/build-a-media-server-with-ampache-and-transmission/). Ampache
is a nice piece of software, with some unique advantages (like Android
support). However, there are simpler ways to stream music. I'm going to
show you how to stream music using sshfs and (optionally) mp3fs. One of
the best things about this approach is that it allows you to access your
collection with the media player of your choice.

Before you start, you're going to need a Linux machine with your music
collection on it (the server). You will also need another Linux machine
to act as the client (e.g. a laptop with a small hard drive).

Configuring the server
----------------------

### Install the ssh server

The first thing you're going to want to do is install an ssh server, if
it's not already installed.

    $ sudo aptitude install openssh-server

If your music is already compressed, or if you just have a very fast
internet connection, you're done configuring the server. Otherwise, read
on to learn how to transcode your music on-the-fly with mp3fs.

### Set up mp3fs

> MP3FS is a read-only FUSE filesystem which transcodes audio formats
> (currently FLAC) to MP3 on the fly when opened and read. This was
> written to enable me to use my FLAC collection with software and/or
> hardware which only understands the MP3 format e.g. gmediaserver to a
> Netgear MP101 MP3 player. --- [Kristofer
> Henriksson](http://khenriks.github.com/mp3fs/)

If you have any music in FLAC format, you're probably not going to be
able to stream it without first transcoding to MP3. mp3fs solves this
problem. First, install it.

    $ sudo aptitude install mp3fs

NOTE: Depending on your distro, the repositories might have an outdated
version of mp3fs. If the following commands don't work, try installing a
newer version of mp3fs (either by compiling it yourself or finding a
newer package).

Now that it's installed, we'll set it up. Create a folder for the mp3fs:

    $ mkdir ~/MP3

Next, add an entry to `/etc/fstab` to automatically mount the mp3fs:

    # cat >> /etc/fstab << EOF
    mp3fs#/home/USER/Music /home/USER/MP3 fuse allow_other,ro,bitrate=320 0 0
    EOF

Make sure you adjust the paths and bitrate, if necessary.

Finally, mount the mp3fs:

    $ sudo mount -a

Now your music collection should appear at `~/MP3` in MP3 format.

Configuring the client
----------------------

We're going to use sshfs to stream the music. It uses SSH to allow you
to mount remote filesystems on the local machine. In other words, it
will make your remote music collection available on the client machine.
To start, install sshfs.

    $ sudo aptitude install sshfs

Now, mount the remote music collection (adjust the parameters as
necessary):

    $ sshfs USER@example.com:Music ~/Music

Your music collection should now be visible on the client at `~/Music`.
Fire up your favorite media player, allow it to scan your music library,
and enjoy.

If you want the sshfs to be automatically mounted, you will first need
to [set up key-based SSH
authentication](http://www.ece.uci.edu/~chou/ssh-key.html). Once that's
done, you will need to edit `/etc/fstab`:

    # cat >> /etc/fstab << EOF
    sshfs#USER@example.com:Music /home/USER/Music fuse defaults,idmap=user 0 0
    EOF

Now your music collection will be available at login.
