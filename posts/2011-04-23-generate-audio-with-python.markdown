---
title: Generate Audio with Python
excerpt: An introduction to audio synthesis in Python using itertools.
---

Introduction
------------
I've been intrigued by the concept of using computers to generate audio
for a long time. It turns out that you can generate audio with nothing
but the standard library of Python.

The approach I used relies heavily on the `itertools` module.
Essentially, I use `itertools` to create infinite generators and then
take some data from these generators to produce the audio. The
resultant sequence of floats in the range [-1.0, 1.0] is converted to 16 bit
PCM audio (i.e., a sequence of signed 16 bit integers in the range
[-32767, 32767]) and then written to a .wav file using the `wave`
module. 
<!--more-->

If you're not familiar with iterators and the `itertools` module, this
post may be somewhat hard to follow. `itertools` really opens up some
interesting possibilities in Python, making it more like Lisp or
Haskell. In truth, if you're relying on `itertools` as much as I am in
this post, you might as well just use Lisp or Haskell and receive a nice
performance boost. The reason I didn't is quite simply 
because I wanted to generate some audio in Python.

To follow the code examples below, you probably need to perform the following imports:

```python
import sys
import wave
import math
import struct
import random
import argparse
from itertools import *
```

Generating Waves
----------------
You may remember from your physics class that sound consists of waves.
Many instruments produce tones that are basically a combination of pure
sine waves. Thus, we need a way to produce sine waves if we want to
generate audio. My first approach was something like this:

```python
def sine_wave(frequency=440.0, framerate=44100, amplitude=0.5):
	if amplitude > 1.0: amplitude = 1.0
    if amplitude < 0.0: amplitude = 0.0
	return (float(amplitude) * math.sin(2.0*math.pi*float(frequency)*(float(i)/float(framerate))) for i in count(0))
```

This computes a sine wave of infinite length at the specified frequency,
and returns an infinite generator which samples the wave 44,100 times
per second. 

The problem with this approach is that it is inefficient. Sine waves are
periodic functions, meaning that they repeat themselves after a certain
period. This means that we can pre-calculate the function for one
period, and then return an iterator which simply cycles these
pre-computed values indefinitely:

```python
def sine_wave(frequency=440.0, framerate=44100, amplitude=0.5):
    period = int(framerate / frequency)
    if amplitude > 1.0: amplitude = 1.0
    if amplitude < 0.0: amplitude = 0.0
    lookup_table = [float(amplitude) * math.sin(2.0*math.pi*float(frequency)*(float(i%period)/float(framerate))) for i in xrange(period)]
    return (lookup_table[i%period] for i in count(0))
```

This resulted in a substantial performance improvement on my machine,
but this is Python after all so a discussion of performance is perhaps a moot
point.

Generating Noise
----------------
Sometimes you want to generate noise. The simplest kind of noise is
called white noise, which is completely random audio data.

```python
def white_noise(amplitude=0.5):
    return (float(amplitude) * random.uniform(-1, 1) for _ in count(0))
```

The main downside to this approach is that random values need to be calculated
44,100 times per second. Using the `itertools` module, we can
pre-calculate one second of white noise, and then just cycle that data:

```python
noise = cycle(islice(white_noise(), 44100))
```

Combining Functions
-------------------
As I mentioned earlier, complex sounds can be modeled as combinations of
pure sine waves. If you're generating a stereo audio file, you can have
different audio functions in each channel. The way I chose to represent
this concept is as follows:
	
```python
c1 = (f1, ..., fn)
c2 = (f1, ..., fn)
channels = (c1, c2)
```

`c1` is the left channel, `c2` is the right channel. Each channel is an
iterable containing the functions that comprise that channel. All
channels are then combined into a single iterable, `channels`.

If you play the same sound through both channels of a stereo audio file, 
the sound will seem to come from the center of the soundstage. 

```python
channels = ((sine_wave(440.0),),
			(sine_wave(440.0),))
```

You can also control the location of the sound by altering the amplitude
of the waves. This example will make a 440.0 Hz sine wave which is
slightly left of center:

```python
channels = ((sine_wave(440.0, amplitude=0.5),),
			(sine_wave(440.0, amplitude=0.2),))
```

Additionally, you can have more than one function playing at the same
time. Here's an example of a 200.0 Hz tone in the left channel, a 205.0
tone in the right channel, and some white noise in the background:

```python
channels = ((sine_wave(200.0, amplitude=0.1), white_noise(amplitude=0.001)),
			(sine_wave(205.0, amplitude=0.1), white_noise(amplitude=0.001)))
```

That's a [binaural beat](http://en.wikipedia.org/wiki/Binaural_beats).

Computing Samples
-----------------
Recall from your physics class that waves combine with each other to
produce new waves. We can compute this new wave by simply adding the
waves together. 

Now that we have defined the audio channels, we need to compute the sum
of the functions in the channel at each sample in the file. Since our waves 
are represented as generators, we want to create a new generator which 
calculates the sum of each sample in the input generators. Essentially
we want a function that accepts audio channels in the format described
above and returns a generator which yields tuples where element 0 is the
sum of the functions in the left channel at that point, and element 1 is
the sum of the functions in the right channel at that point.

This calls for use of the `imap` and `izip` functions. 

```python
def compute_samples(channels, nsamples=None):
    return islice(izip(*(imap(sum, izip(*channel)) for channel in channels)), nsamples)
```

Note that if `nsamples` is specified, we return a sequence of finite
length (using the `islice` function). Otherwise, we return a sequence of
infinite length. Since we are using iterators, sequences of infinite
length can be represented more or less elegantly and efficiently.

Writing a Wavefile
------------------
The next step is to use the `wave` module to create a `.wav` file. The
first thing to do is to generate the wave header, which is some
information at the beginning of the wavefile that describes the contents
of the file. The information we need to generate this header is as
follows:

* `nchannels` - the number of channels contained in the file. For stereo, this is 2.
* `sampwidth` - the size of each sample, in bytes. Recall that a byte is 8 bits, so for 16 bit audio this is 2.
* `framerate` - the number of samples per second. I usually set this to 44100 (CD quality).
* `nframes` - the total number of samples to write. This is equal to the framerate multiplied by the duration of the file in seconds.

To open a wavefile for writing with the `wave` module, do this:

```python
w = wave.open(filename, 'w')
w.setparams((nchannels, sampwidth, framerate, nframes, 'NONE', 'not compressed'))
```

The `'NONE'` and `'not compressed'` just indicate that we are creating an
uncompressed wavefile (nothing else is supported by the `wave` module at
the time of writing).

Now the wavefile is ready for our audio data. 16 bit audio is encoded
as a series of signed 16 bit integers. The first thing to do is to scale
our sequence of floats in the range [-1.0, 1.0] to signed 16 bit
integers (in the range [-32767, 32767]). For example:

```python
max_amplitude = 32767.0
samples = (int(sample * max_amplitude) for sample in samples)
```

We're writing a binary format, so we need the `struct` module 
to convert our audio data to the correct binary encoding. Specifically,
we need the `struct.pack` function. The `struct.pack` function uses 
format strings to designate how to pack the data. A signed 16 bit
integer is also known as a signed short, so we want to use the format
string 'h' (the format string for a signed short). Thus, to pack the
integer 1000 into a signed short:

```python
struct.pack('h', 1000)
```

Now, we are going to be creating stereo audio files, so we need to
consider how `.wav` files represent multiple channels. It turns out
that `.wav` files look something like this:

	L1R1L2R2L3R3L4R4

Where `L1` is the first sample in the left channel, `R1` is the first
sample in the right channel, and so on. In other words, the channels are
interleaved.

Finally, we want to keep performance in mind. On one extreme, we write
data to the file every time we compute a sample. This is
memory-efficient, but incurs a severe performance penalty due to the
overhead of writing to the file. On the other extreme, we pre-compute
the entire file and write all of the samples at once. This does not
incur the aforementioned performance penalty, but it has two major
problems. First, it requires a huge amount of memory, since the entire
`.wav` file will be loaded into memory. Second, it means you can't
stream the audio as it is generated, which means you can't play the 
audio in realtime (by writing to `stdout` and piping to `aplay`, for 
example).

Thus, we take the third approach: buffer chunks of the audio
stream and write each chunk as it is computed. This offers the
advantages of both techniques.

So, putting all of this together, we end up with something like this:

```python
def grouper(n, iterable, fillvalue=None):
    "grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args)

def write_wavefile(filename, samples, nframes=None, nchannels=2, sampwidth=2, framerate=44100, bufsize=2048):
    if nframes is None:
        nframes = -1
	
    w = wave.open(filename, 'w')
    w.setparams((nchannels, sampwidth, framerate, nframes, 'NONE', 'not compressed'))

    max_amplitude = float(int((2 ** (sampwidth * 8)) / 2) - 1)

    # split the samples into chunks (to reduce memory consumption and improve performance)
    for chunk in grouper(bufsize, samples):
        frames = ''.join(''.join(struct.pack('h', int(max_amplitude * sample)) for sample in channels) for channels in chunk if channels is not None)
        w.writeframesraw(frames)
    
    w.close()

    return filename
```

`wavebender`
------------
I have compiled these techniques and a few others into a module 
called `wavebender`. Here's the current source code (at the time
of writing), but you can always find the latest
at <https://github.com/zacharydenton/wavebender>.

```python
#!/usr/bin/env python
import sys
import wave
import math
import struct
import random
import argparse
from itertools import *

def grouper(n, iterable, fillvalue=None):
    "grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return izip_longest(fillvalue=fillvalue, *args)

def sine_wave(frequency=440.0, framerate=44100, amplitude=0.5):
    '''
    Generate a sine wave at a given frequency of infinite length.
    '''
    period = int(framerate / frequency)
    if amplitude > 1.0: amplitude = 1.0
    if amplitude < 0.0: amplitude = 0.0
    lookup_table = [float(amplitude) * math.sin(2.0*math.pi*float(frequency)*(float(i%period)/float(framerate))) for i in xrange(period)]
    return (lookup_table[i%period] for i in count(0))

def square_wave(frequency=440.0, framerate=44100, amplitude=0.5):
    for s in sine_wave(frequency, framerate, amplitude):
        if s > 0:
            yield amplitude
        elif s < 0:
            yield -amplitude
        else:
            yield 0.0

def damped_wave(frequency=440.0, framerate=44100, amplitude=0.5, length=44100):
    if amplitude > 1.0: amplitude = 1.0
    if amplitude < 0.0: amplitude = 0.0
    return (math.exp(-(float(i%length)/float(framerate))) * s for i, s in enumerate(sine_wave(frequency, framerate, amplitude)))

def white_noise(amplitude=0.5):
    '''
    Generate random samples.
    '''
    return (float(amplitude) * random.uniform(-1, 1) for i in count(0))

def compute_samples(channels, nsamples=None):
    '''
    create a generator which computes the samples.

    essentially it creates a sequence of the sum of each function in the channel
    at each sample in the file for each channel.
    '''
    return islice(izip(*(imap(sum, izip(*channel)) for channel in channels)), nsamples)

def write_wavefile(filename, samples, nframes=None, nchannels=2, sampwidth=2, framerate=44100, bufsize=2048):
    "Write samples to a wavefile."
    if nframes is None:
        nframes = -1

    w = wave.open(filename, 'w')
    w.setparams((nchannels, sampwidth, framerate, nframes, 'NONE', 'not compressed'))

    max_amplitude = float(int((2 ** (sampwidth * 8)) / 2) - 1)

    # split the samples into chunks (to reduce memory consumption and improve performance)
    for chunk in grouper(bufsize, samples):
        frames = ''.join(''.join(struct.pack('h', int(max_amplitude * sample)) for sample in channels) for channels in chunk if channels is not None)
        w.writeframesraw(frames)
    
    w.close()

    return filename

def write_pcm(f, samples, sampwidth=2, framerate=44100, bufsize=2048):
    "Write samples as raw PCM data."
    max_amplitude = float(int((2 ** (sampwidth * 8)) / 2) - 1)

    # split the samples into chunks (to reduce memory consumption and improve performance)
    for chunk in grouper(bufsize, samples):
        frames = ''.join(''.join(struct.pack('h', int(max_amplitude * sample)) for sample in channels) for channels in chunk if channels is not None)
        f.write(frames)
    
    f.close()

    return filename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--channels', help="Number of channels to produce", default=2, type=int)
    parser.add_argument('-b', '--bits', help="Number of bits in each sample", choices=(16,), default=16, type=int)
    parser.add_argument('-r', '--rate', help="Sample rate in Hz", default=44100, type=int)
    parser.add_argument('-t', '--time', help="Duration of the wave in seconds.", default=60, type=int)
    parser.add_argument('-a', '--amplitude', help="Amplitude of the wave on a scale of 0.0-1.0.", default=0.5, type=float)
    parser.add_argument('-f', '--frequency', help="Frequency of the wave in Hz", default=440.0, type=float)
    parser.add_argument('filename', help="The file to generate.")
    args = parser.parse_args()

    # each channel is defined by infinite functions which are added to produce a sample.
    channels = ((sine_wave(args.frequency, args.rate, args.amplitude),) for i in range(args.channels))

    # convert the channel functions into waveforms
    samples = compute_samples(channels, args.rate * args.time)

    # write the samples to a file
    if args.filename == '-':
        filename = sys.stdout
    else:
        filename = args.filename
    write_wavefile(filename, samples, args.rate * args.time, args.channels, args.bits / 8, args.rate)

if __name__ == "__main__":
    main()
```

You can execute the file directly and it will generate a pure sine tone.

Examples
--------
### SBaGen ###
[SBaGen](http://uazu.net/sbagen/) is a program which generates binaural beats. It's reasonably complex, consisting
of around 3000 lines of C. You can instruct SBaGen to generate a 200Hz pure sine tone in one 
channel and a 204Hz pure sine tone in the other channel by doing this:

```console
$ sbagen -i 202+2/10
```

You can also generate multiple binaural beats simultaneously:

```console
$ sbagen -i 202+2/10 400+20/10
```

The following emulates `sbagen -i`, but it's about 100x slower. No problem for
real-time use on a modern computer, but you're better off using the real deal
for serious use.

```python
#!/usr/bin/env python
import re
import sys
from wavebender import *
from itertools import *

def sbagen_phrase(phrase):
    '''
    147.0+4.0/1.27 -> two sine_waves. one 145.0 hz; one 149.0 hz. each at amplitude of 0.0127.
    '''
    if 'pink' in phrase:
		# pink/40 -> white_noise(amplitude=0.4)
        amplitude = float(phrase.split('/')[-1]) / 100.0
        return (white_noise(amplitude),
                white_noise(amplitude))

    carrier, remainder = re.split('[+-]', phrase, 1)
    beatfreq, amplitude = remainder.split('/')

    carrier = float(carrier)
    beatfreq = float(beatfreq)
    amplitude = float(amplitude) / 100.0

    return (sine_wave((carrier - beatfreq/2), amplitude=amplitude),
            sine_wave((carrier + beatfreq/2), amplitude=amplitude))

def sbagen_line(line, length=None):
    '''
    Given a sequence of (l, r), (l, r), return a sequence of (l, l), (r, r).
    '''
    return izip(*(imap(lambda s: islice(s, length), sbagen_phrase(phrase)) for phrase in line.split()))

if sys.argv[1:]:
    channels = sbagen_line(' '.join(sys.argv[1:]))
else:
    sys.exit(1)

samples = compute_samples(channels)
write_wavefile(sys.stdout, samples)
```

You can use it like this:

```console
$ ./sbagen.py 272.2+7.83/10 332+7.83/10 421.3+7.83/10 289.4+7.83/10 367.5+7.83/10 442+7.83/10 295.7+7.83/10 414.7+7.83/10 422+7.83/10 | aplay
```

That generates a bunch of simultaneous binaural tones and uses `aplay`
to play them in realtime.

### Melody ###
Here's an example of a melody, using `itertools` and `wavebender`.

``` python 
#!/usr/bin/env python
from wavebender import *
from itertools import *
import sys

def ncycles(iterable, n):
    "Returns the sequence elements n times"
    return chain.from_iterable(repeat(tuple(iterable), n))

def waves():
    l = int(44100*0.4) # each note lasts 0.4 seconds
    
    return cycle(chain(ncycles(chain(islice(damped_wave(frequency=440.0, amplitude=0.1, length=int(l/4)), l),
                                     islice(damped_wave(frequency=261.63, amplitude=0.1, length=int(l/4)), l),
                                     islice(damped_wave(frequency=329.63, amplitude=0.1, length=int(l/4)), l)), 3),
                       islice(damped_wave(frequency=440.0, amplitude=0.1, length=3*l), 3*l),
                 
                       ncycles(chain(islice(damped_wave(frequency=293.66, amplitude=0.1, length=int(l/4)), l),
                                     islice(damped_wave(frequency=261.63, amplitude=0.1, length=int(l/4)), l),
                                     islice(damped_wave(frequency=293.66, amplitude=0.1, length=int(l/4)), l)), 2),
                       chain(islice(damped_wave(frequency=293.66, amplitude=0.1, length=int(l/4)), l),
                             islice(damped_wave(frequency=329.63, amplitude=0.1, length=int(l/4)), l),
                             islice(damped_wave(frequency=293.66, amplitude=0.1, length=int(l/4)), l)),
                       islice(damped_wave(frequency=261.63, amplitude=0.1, length=3*l), 3*l)))

channels = ((waves(),), (waves(), white_noise(amplitude=0.001),))

samples = compute_samples(channels, None)
write_wavefile(sys.stdout, samples, None)
```

Conclusion
----------

Well, there's your daily abuse of `itertools`. For more `itertools`
madness, check out my [Project Euler Solutions](/project-euler-solutions/).
