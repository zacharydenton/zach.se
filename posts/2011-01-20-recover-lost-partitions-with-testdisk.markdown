--- 
title: Recover Lost Partitions with TestDisk
excerpt: How to recover data from broken hard drives with a program called TestDisk.
---

I was recently messing around with the `dd` program to write ISO images
to USB drives, instead of wasting DVDs or CDs. The command to do this is
as follows:

```
# dd if=archlinux-2010.05-netinstall-x86_64.iso of=/dev/sdX
```

Where `sdX` is the device name of the disk you wish to write the image
to.

This is alright if you only have two disks in your computer, where you
would almost certainly want to write to `/dev/sdb`. However, if you have
more than two disks, you need to be absolutely sure that you have
selected the correct device --- choose the wrong disk, and its data will
be overwritten by that of the ISO image.

This is precisely what happened to me (twice, in fact!). I thought I was
writing to my flash drive but it turned out that I was actually writing
to my 1TB external backup drive. Luckily I had the presence of mind to
kill the dd process after I realized that the activity light on the
flash drive was not blinking, but the 80MB or so of data that was
written was enough to destroy the
<abbr title="Master Boot Record">MBR</abbr>. That's a big problem
because the MBR acts like a map telling the computer where data is
located on the drive. Without that map, the drive is useless.

Thankfully, one Christophe Grenier has written a program called
[TestDisk](http://www.cgsecurity.org/wiki/TestDisk) which
scans the raw data of the hard drive and searches for lost partitions. I
was able to recover the lost partitions on my drive using this fantastic
tool.

It uses a few different methods to recover the lost partitions. First,
it quickly scans through the entire hard drive, looking for lost
partitions. Then, it gives you the option to perform a deeper search,
which inspects the drive more carefully. Finally, it checks if there is
a backup MBR on the device, and if so, uses it to replace the lost MBR.

This final option worked for me. Personally, I think this should be the
first step performed, as it takes several hours to scan the entire drive
twice whereas it presumably takes less than a second to inspect the
backup MBR.

Check out
this [step-by-step
guide](http://www.cgsecurity.org/wiki/TestDisk_Step_By_Step) detailing
its use.
