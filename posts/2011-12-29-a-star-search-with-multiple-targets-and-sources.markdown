---
title: A* Search with Multiple Targets and Sources
excerpt: An extension of the A* algorithm to support pathfinding from many starting points to many goal points in a single pass.
---

A couple months ago, I decided to expand my knowledge of artificial
intelligence by participating in the [2011 AI
Challenge](http://aichallenge.org). It was an incredibly interesting and
educational experience. Sadly, I was forced to divert my attention away
from the AI Challenge to focus on more important things.

One of the more interesting things I learned from the AI Challenge was
an A\* algorithm which supports searching from multiple sources to
multiple targets, simultaneously. I used this algorithm to efficiently
gather food: one pass of this algorithm calculated paths to each food
tile.

The algorithm is similar to the basic A\*, except for a few key
differences. First of all, the frontier is prepopulated with all of the
sources. Secondly, the goal test function checks to see if the current
position corresponds to *any* of the targets, not just a single target.
Finally, the heuristic is the Manhattan distance to the *nearest*
target.

This is the algorithm in pseudocode:

    frontier = {sources}
    explored = {}
    loop:
        if frontier is empty: return
        path = remove_choice(frontier) # minimize f + h where h = distance to nearest target
        s = path.end
        add s to explored
        if s in targets: command source to follow path
        for a in actions:
            add [path + a -> Result(s, a)] to frontier
                unless Result(s, a) in frontier + explored

I've [uploaded my bot to
GitHub](https://github.com/zacharydenton/aichallenge-ants), so you can
actually [see this algorithm in
practice](https://github.com/zacharydenton/aichallenge-ants/blob/master/MyBot.java#L237)
if you want.
