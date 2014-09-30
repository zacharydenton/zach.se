---
title: How To Display BuddyPress Album Images Anywhere
excerpt: How to use the BuddyPress Album+ loop to display images anywhere on your WordPress site.
---

Recently, I created a new landing page for [Ultralight Backpacking
Network][]. It features a grid of images posted by the site's users.
Ultralight Backpacking Network is using BuddyPress Album+ to manage
users' photo albums, so I needed to figure out a way to display
BuddyPress Album+ images anywhere on the site. It turns out that
BuddyPress Album+ makes this a relatively easy task. You retrieve the
images using a loop, a process familiar to anyone who has modified or
created a WordPress theme. Here's an example of a BuddyPress Album+
loop:

~~~~ {.html}
<div id="photos">
<?php bp_album_query_pictures('per_page=5'); ?>
<?php if ( bp_album_has_pictures() ) : ?>
        <ul class="thumb">
        <?php while ( bp_album_has_pictures() ) : bp_album_the_picture(); ?>
                <li>
                        <a href="<?php bp_album_picture_middle_url(); ?>" title="<?php bp_album_picture_title(); ?>">
                                <img src='<?php bp_album_picture_thumb_url() ?>' alt="<?php bp_album_picture_desc(); ?>" />
                        </a>
                </li>
        <?php endwhile; ?>
        </ul> 
<?php endif; ?>
</div>
~~~~

Notice how similar it is to the WordPress loop. An important thing to
remember is that you must first call the function
`bp_album_query_pictures()` before you can start the BuddyPress Album+
Loop. This function initializes the Query object used for the loop. The
`bp_album_query_pictures()` function supports a few different
parameters:

-   **owner\_id** - This is the numeric ID of the user whose photos you
    wish to display.
-   **id** - This is the numeric ID of the photo you wish to display.
    Only used if you wish to display a single photo.
-   **privacy** - Retrieve photos based on privacy settings. Can be one
    of the following:
    -   *public* - photos visible to everyone
    -   *members* - photos visible to members
    -   *friends*- photos visible to friends of the current user
    -   *private*- photos visible to the current user
    -   *admin*- photos visible to the site administrator

-   **adjacent**- Used to select a photo immediately preceding or
    succeeding the photo specified by **id**. Use one of either:
    -   *next* - select the next photo
    -   *prev* - select the previous photo

-   **orderkey**- Specify which field to use to sort the photos. This is
    one of the following:
    -   *id* - sort by the numeric ID of the photos
    -   *user\_id*- sort by the numeric ID of the users who uploaded the
        photos
    -   *status*- sort based on the status of the photos

-   **ordersort**- Specify the order in which to sort the photos. One of
    either:
    -   *ASC* - sort in ascending order
    -   *DESC* - sort in descending order

-   **per\_page** - The number of photos you would like to display per
    page. If you want 24 photos, this is where you would specify that.
-   **offset**- Start selecting photos after a certain offset.

Once you've started the loop, you have a few different options depending
on how you want to display the data. Here are some of the template tags
you can use:

-   **bp\_album\_picture\_title** - Prints the title of the image.
-   **bp\_album\_picture\_desc** - Prints the image description.
-   **bp\_album\_picture\_id** - Prints the numeric ID of the image.
-   **bp\_album\_picture\_url** - Prints the URL to the page where the
    image is located.
-   **bp\_album\_picture\_original\_url** - Prints the URL to the
    original image.
-   **bp\_album\_picture\_middle\_url** - Prints the URL to the scaled
    image.
-   **bp\_album\_picture\_thumb\_url**- Prints the URL to the image
    thumbnail.
-   **bp\_album\_adjacent\_links** - Prints links to the preceding and
    succeeding albums or images.

There are several other template tags you can use -- too many to list
here, in fact. For more information, check out
`includes/bp-album-templatetags.php` in the `bp-album` folder. If you
want to display information about the album author, you are going to
need a few additional template tags that don't come with BuddyPress
Album+ by default. See [this post][] for more details. That's enough
information to get you up and running with custom BuddyPress Album+
themes.

  [Ultralight Backpacking Network]: http://ultralightbackpacking.net
    "Ultralight Backpacking Network"
  [this post]: /buddypress-album-author-template-tags/
    "BuddyPress Album Author Template Tags"
