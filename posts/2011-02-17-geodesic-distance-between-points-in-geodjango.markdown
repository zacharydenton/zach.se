--- 
title: Geodesic Distance Between Points in GeoDjango
excerpt: Various ways to perform geodesic distance calculations in Django.
---

Background
----------

I'm working on a Django project which deals with geographic data. To
handle this data, I'm using GeoDjango (django.contrib.gis), which is a
fantastic framework for working with GIS information in Django. The data
I am using consists of points scattered across the Earth, so I decided
to store the geographic information in the WGS84 datum (SRID 4326), the
system used by GPS.

The problem is that since WGS84 is a geographic coordinate system, as
opposed to a projected coordinate system, GeoDjango returns the
Cartesian distance between points as a float value in degrees. This is
not useful for presenting to users, since we deal with kilometers and
miles in everyday life. The distance we want is known as the [geodesic
distance](http://en.wikipedia.org/wiki/Geodesy "Geodesy").

Geodesic Distance
-----------------

Geodesic distance refers to the distance between two points if you were
to travel between them on the Earth's surface. Thus, it is the 'real'
distance between two points, as opposed to the theoretical distance
returned by GeoDjango.

The formulae used to calculate this distance are [quite
complex](http://en.wikipedia.org/wiki/Vincenty%27s_formulae "Vincenty's formulae").
Luckily, they have been implemented for us in a Python module called
[geopy](http://code.google.com/p/geopy/wiki/GettingStarted#Calculating_distances "Calculating Distances with geopy").
The specific method we will be using is known as Vincenty's method. It's
accurate to within 0.5mm!

The specific function is `geopy.distance.distance`. Here's a simple
example demonstrating its use:

~~~~ {.python}
>>> from geopy.distance import distance as geopy_distance
>>> washington = (38.53, 77.02)
>>> chicago = (41.50, 87.37)
>>> d = geopy_distance(washington, chicago)
>>> print d.meters
942408.377797
>>> print d.miles
585.585417063
~~~~

Notice how converting between different units of measure on the
resultant `Distance` object is as simple as accessing different
attributes of that object (in this case, `meters` and `miles`).

Solution
--------

In the example below, we have a Route object which can be associated
with an arbitrary number of waypoints. Since the geopy distance function
only works on two points, we use the itertools module to take the points
pairwise so that we can calculate the distance for each pair and find
the sum of the distances. Once we have calculated the geodesic distance
with geopy and itertools, we turn it into a GeoDjango Distance object,
which allows us to seamlessly convert to several different kinds of
units as well as interface with the rest of GeoDjango's spatial query
functions.

Here's an example `models.py` which demonstrates this approach:

~~~~ {.python}
from itertools import tee, izip

from django.contrib.gis.db import models
from django.contrib.gis.measure import Distance

from geopy.distance import distance as geopy_distance

def pairwise(iterable):
    "s -> (s0,s1), (s1,s2), (s2, s3), ..."
    a, b = tee(iterable)
    next(b, None)
    return izip(a, b)

# Create your models here.
class Route(models.Model):
    name = models.CharField(max_length=100)

    def length(self):
        '''Determine the length of the route.'''
        points = (waypoint.point for waypoint in self.waypoint_set.orderby('time'))
        meters = sum(geopy_distance(a, b).meters for (a, b) in pairwise(points))
        return Distance(m=meters)

class Waypoint(models.Model):
    time = models.DateTimeField()
    route = models.ForeignKey(Route)
    point = models.PointField(srid=4326)
    objects = models.GeoManager()

def distance(*points):
    '''
    Find the geodesic distance between two or more points.

    If more than two points are specified, the points are assumed
    to be on a route. The total length of this route is
    calculated.

    Returns a django.contrib.gis.measure.Distance object.
    '''
    meters = sum(geopy_distance(a, b).meters for (a, b) in pairwise(points))
    return Distance(m=meters)

def example():
    from django.contrib.gis.geos import Point
    # Calculate the distance to San Franciso from Washington, D.C., via Chicago.
    washington = Point(38.53, 77.02)
    chicago = Point(41.50, 87.37)
    san_francisco = Point(37.47, 122.26)

    d = distance(washington, chicago, san_francisco)
    print "Washington, D.C. -> Chicago -> San Francisco:"
    print "%(miles)0.2f miles, or %(kilometers)0.2f kilometers (or %(fathoms)0.2f fathoms)" % {
            'miles': d.mi,
            'kilometers': d.km,
            'fathoms': d.fathom
    }
~~~~

~~~~ {.python}
>>> import app.models
>>> app.models.example()
Washington, D.C. -> Chicago -> San Francisco:
2458.41 miles, or 3956.42 kilometers (or 2163398.31 fathoms)
~~~~

The distance function can either be used on its own or as an instance
method, as in Route.length(). If you have any questions, feel free to
ask in the comments.

Additional Notes
----------------

### Projected Coordinate Systems

If your data is concentrated in a small area, then you could use a
[projected coordinate
system](http://docs.djangoproject.com/en/dev/ref/contrib/gis/db-api/#distance-lookups "GeoDjango Distance Lookups")
(such as SRID 32140, for South Texas) to solve the problem.

### PostGIS Geography Field Type

Alternatively, you could try storing your data using the [PostGIS
Geography field
type](http://postgis.refractions.net/docs/ch04.html#PostGIS_Geography "PostGIS Geography Field Type"),
which performs geodesic calculations instead of Cartesian calculations.
The downside with this approach is that it prevents you from using many
of the GeoDjango functions. For instance, none of the Spatial Aggregate
functions worked, in my testing. Since this is a relatively new PostGIS
feature, I expect it to become more usable in the future. Once it does,
I recommend using that instead, as it makes more sense to have these
kinds of calculations occur seamlessly at the database level.
