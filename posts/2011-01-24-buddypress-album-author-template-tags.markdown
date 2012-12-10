--- 
title: BuddyPress Album Author Template Tags
excerpt: How to create custom BuddyPress Album+ loops using template tags.
---

So you've set up a [BuddyPress Album+
loop](/programming/how-to-display-buddypress-album-images-anywhere/ "How To Display BuddyPress Album Images Anywhere")
to place BuddyPress Album+ images anywhere on your site. You're using
the built-in template tags to display the images, along with some
information about each one. These built-in template tags are great for
most purposes, but if you want to display information about the image
author, you were previously out of luck.

To fill that void, I've written a couple of basic template tags which
retrieve information about the author of the current image in the loop.
Just add these template tags to the `functions.php` file in your theme
directory, and you will be able to use them right away.

~~~~ {.php}
<?php
function bp_album_get_author_userdata() {
        global $pictures_template;
        $author_userdata = get_userdata($pictures_template->picture->owner_id);
        return $author_userdata;
}


function bp_album_get_the_author() {
        $author_userdata = bp_album_get_author_userdata();
        return $author_userdata->display_name;
}
?>
~~~~

The function `bp_album_get_author_userdata()` retrieves all of the
author information and returns it as an object. See the function
reference for `get_userdata()` for more information about how to use
this object.

The second function, `bp_album_get_the_author()`, works similarly to
`get_the_author()`. It simply returns the display name of the author of
the current image in the loop.
