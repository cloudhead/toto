toto
====

the tiniest blogging engine in Oz!

introduction
------------

toto is a git-powered, minimalist blog engine for the hackers of Oz. The engine weighs around ~300 sloc at its worse.
There is no toto client, at least for now; everything goes through git.

blog in 10 seconds
------------------

    $ git clone git://github.com/cloudhead/dorothy.git myblog
    $ cd myblog
    $ heroku create myblog
    $ git push heroku master

philosophy
----------

Everything that can be done better with another tool should be, but one should not have too much pie to stay fit.
In other words, toto does away with web frameworks or DSLs such as sinatra, and is built right on top of **rack**.
There is no database or ORM either, we use plain text files.

Toto was designed to be used with a reverse-proxy cache, such as [Varnish](http://varnish-cache.org).
This makes it an ideal candidate for [heroku](http://heroku.com).

Oh, and everything that can be done with git, _is_.

how it works
------------

- content is entirely managed through **git**; you get full fledged version control for free.
- articles are stored as _.txt_ files, with embeded metadata (in yaml format).
- articles are processed through a markdown converter (rdiscount) by default.
- templating is done through **ERB**.
- toto is built right on top of **Rack**.
- toto was built to take advantage of _HTTP caching_.
- toto was built with heroku in mind.
- comments are handled by [disqus](http://disqus.com)
- individual articles can be accessed through urls such as _/2009/11/21/blogging-with-toto_
- the archives can be accessed by year, month or day, wih the same format as above.
- arbitrary metadata can be included in articles files, and accessed from the templates.
- summaries are generated intelligently by toto, following the `:max` setting you give it.
- you can also define how long your summary is, by adding `~` at the end of it (`:delim`).

dorothy
-------

Dorothy is toto's default template, you can get it at <http://github.com/cloudhead/dorothy>. It
comes with a very minimalistic but functional template, and a _config.ru_ file to get you started.
It also includes a _.gems_ file, for heroku.

synopsis
--------

One would start by installing _toto_, with `sudo gem install toto`, and then forking or
cloning the `dorothy` repo, to get a basic skeleton:

    $ git clone git://github.com/cloudhead/dorothy.git weblog
    $ cd weblog/

One would then edit the template at will, it has the following structure:

    templates/
    |
    +- layout.rhtml      # the main site layout, shared by all pages
    |
    +- index.builder     # the builder template for the atom feed
    |
    +- pages/            # pages, such as home, about, etc go here
       |
       +- index.rhtml    # the default page loaded from `/`, it displays the list of articles
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
and the rest of it is the blog post. They are delimited by an empty line `/\n\n/`, as you can see above.
None of the information is compulsory, but it's strongly encouraged you specify it.
Note that one can also use `rake` to create an article stub, with `rake new`.

Once he finishes writing his beautiful tale, one can push to the git repo, as usual:

    $ git add articles/wizard-of-oz.txt
    $ git commit -m 'wrote the wizard of oz.'
    $ git push remote master

Where `remote` is the name of your remote git repository. The article is now published.

### deployment

Toto is built on top of **Rack**, and hence has a **rackup** file: _config.ru_.

#### on your own server

Once you have created the remote git repo, and pushed your changes to it, you can run toto with any Rack compliant web server,
such as **thin**, **mongrel** or **unicorn**.

With thin, you would do something like:

    $ thin start -R config.ru

With unicorn, you can just do:

    $ unicorn

#### on heroku

Toto was designed to work well with [heroku](http://heroku.com), it makes the most out of it's state-of-the-art caching,
by setting the _Cache-Control_ and _Etag_ HTTP headers. Deploying on Heroku is really easy, just get the heroku gem,
create a heroku app with `heroku create`, and push with `git push heroku master`.

    $ heroku create weblog
    $ git push heroku master
    $ heroku open

### configuration

You can configure toto, by modifying the _config.ru_ file. For example, if you want to set the blog author to 'John Galt',
you could add `set :author, 'John Galt'` inside the `Toto::Server.new` block. Here are the defaults, to get you started:

    set :author,      ENV['USER']                               # blog author
    set :title,       Dir.pwd.split('/').last                   # site title
    set :url,         'http://example.com'                      # site root URL
    set :prefix,      ''                                        # common path prefix for all pages
    set :root,        "index"                                   # page to load on /
    set :date,        lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
    set :markdown,    :smart                                    # use markdown + smart-mode
    set :disqus,      false                                     # disqus id, or false
    set :summary,     :max => 150, :delim => /~\n/              # length of article summary and delimiter
    set :ext,         'txt'                                     # file extension for articles
    set :cache,       28800                                     # cache site for 8 hours

    set :to_html   do |path, page, ctx|                         # returns an html, from a path & context
      ERB.new(File.read("#{path}/#{page}.rhtml")).result(ctx)
    end

    set :error     do |code|                                    # The HTML for your error page
      "<font style='font-size:300%'>toto, we're not in Kansas anymore (#{code})</font>"
    end

thanks
------

To heroku for making this easy as pie.
To adam wiggins, as I stole a couple of ideas from Scanty.
To the developpers of Rack, for making such an awesome platform.

Copyright (c) 2009-2010 cloudhead. See LICENSE for details.
