toto
====

the tiniest blogging engine in Oz!

introduction
------------

toto is a git-powered, minimalist blog engine for the hackers of Oz.
There is no toto client, at least for now; everything goes through git.

synopsis
--------

One would start by forking or cloning the toto-skeleton repo, to get a basic skeleton:

    $ git clone git://github.com/cloudhead/toto-skeleton.git

One would then edit the template at will, it has the following structure:

    templates/
    |
    +- layout.html   # the main site layout, shared by all pages
    |
    +- article.html  # the article (post) partial
    |
    +- pages/        # pages, such as home, about, etc go here
       |
       +- home.html  # the default page loaded from `/`, it displays the list of articles

One could then create a .txt article file in the `articles/` folder, and make sure it has the following format:

    title: The Wonderful Wizard of Oz
    author: Lyman Frank Baum
    date: 1900/05/17

    Dorothy lived in the midst of the great Kansas prairies, with Uncle Henry, 
    who was a farmer, and Aunt Em, who was the farmer's wife.
  
If one is familiar with webby or aerial, this shouldn't look funny. Basically the top of the file is in YAML format, and the rest of it is the blog post.
They are delimited by an empty line `/\n\n/`, as you can see above. None of the information is compulsory, but it's strongly encouraged you specify it.

Once he finishes writing his beautiful tale, one can push to the git repo, as usual:

    $ git add articles/wizard-of-oz.txt
    $ git commit -m 'wrote the wizard of oz.'
    $ git push remote master

Where `remote` is the name of your remote git server.

### Server ###

info coming soon!

Copyright (c) 2009 cloudhead. See LICENSE for details.
