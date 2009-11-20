toto
====

the tiniest blogging engine in Oz!

introduction
------------

toto is a git-powered, minimalist blog engine for the hackers of Oz. The engine weights around ~200 sloc at its worse.
There is no toto client, at least for now; everything goes through git.

synopsis
--------

One would start by forking or cloning the toto-skeleton repo, to get a basic skeleton:

    $ git clone git://github.com/cloudhead/toto-skeleton.git

One would then edit the template at will, it has the following structure:

    templates/
    |
    +- layout.rhtml      # the main site layout, shared by all pages
    |
    +- feed.builder      # the builder template for the atom feed
    |
    +- pages/            # pages, such as home, about, etc go here
       |
       +- home.rhtml     # the default page loaded from `/`, it displays the list of articles
       |
       +- article.rhtml  # the article (post) partial and page
       |
       +- about.rhtml

One could then create a .txt article file in the `articles/` folder, and make sure it has the following format:

    title: The Wonderful Wizard of Oz
    author: Lyman Frank Baum
    date: 1900/05/17

    Dorothy lived in the midst of the great Kansas prairies, with Uncle Henry, 
    who was a farmer, and Aunt Em, who was the farmer's wife.
  
If one is familiar with webby or aerial, this shouldn't look funny. Basically the top of the file is in YAML format,
and the rest of it is the blog post.They are delimited by an empty line `/\n\n/`, as you can see above. 
None of the information is compulsory, but it's strongly encouraged you specify it.
Note that one can also use `rake` to create an article stub, with `rake new`.

Once he finishes writing his beautiful tale, one can push to the git repo, as usual:

    $ git add articles/wizard-of-oz.txt
    $ git commit -m 'wrote the wizard of oz.'
    $ git push remote master

Where `remote` is the name of your remote git server.

### Server ###

For the server, there is one important file: _server.ru_ 

Copyright (c) 2009 cloudhead. See LICENSE for details.
