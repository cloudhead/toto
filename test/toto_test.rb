require 'test/test_helper'

URL = "http://toto.oz"
AUTHOR = "toto"

context Toto do
  setup do
    @config = Toto::Config.new(:markdown => true, :author => AUTHOR, :url => URL)
    @toto = Rack::MockRequest.new(Toto::Server.new(@config))
    Toto::Paths[:articles] = "test/articles"
    Toto::Paths[:pages] = "test/templates"
    Toto::Paths[:templates] = "test/templates"
  end

  context "GET /" do
    setup { @toto.get('/') }

    asserts("returns a 200")                { topic.status }.equals 200
    asserts("body is not empty")            { not topic.body.empty? }
    asserts("content type is set properly") { topic.content_type }.equals "text/html"
    should("include a couple of article")   { topic.body }.includes_elements("#articles li", 3)
    should("include an archive")            { topic.body }.includes_elements("#archives li", 2)

    context "with no articles" do
      setup { Rack::MockRequest.new(Toto::Server.new(@config.merge(:ext => 'oxo'))).get('/') }

      asserts("body is not empty")          { not topic.body.empty? }
      asserts("returns a 200")              { topic.status }.equals 200
    end
  end

  context "GET /about" do
    setup { @toto.get('/about') }
    asserts("returns a 200")                { topic.status }.equals 200
    asserts("body is not empty")            { not topic.body.empty? }
    should("have access to @articles")      { topic.body }.includes_html("#count" => /5/)
  end

  context "GET a single article" do
    setup { @toto.get("/1900/05/17/the-wonderful-wizard-of-oz") }
    asserts("returns a 200")                { topic.status }.equals 200
    asserts("content type is set properly") { topic.content_type }.equals "text/html"
    should("contain the article")           { topic.body }.includes_html("p" => /<em>Once upon a time<\/em>/)
  end

  context "GET to the archive" do
    context "through a year" do
      setup { @toto.get('/2009') }
      asserts("returns a 200")                     { topic.status }.equals 200
      should("includes the entries for that year") { topic.body }.includes_elements("li.entry", 3)
    end

    context "through a year & month" do
      setup { @toto.get('/2009/12') }
      asserts("returns a 200")                      { topic.status }.equals 200
      should("includes the entries for that month") { topic.body }.includes_elements("li.entry", 2)
      should("includes the year & month")           { topic.body }.includes_html("h1" => /2009\/12/)
    end

    context "through /archive" do
      setup { @toto.get('/archive') }
    end
  end

  context "GET to an unknown route" do
    setup { @toto.get('/unknown') }
    should("returns a 404") { topic.status }.equals 404
  end

  context "Request is invalid" do
    setup { @toto.delete('/invalid') }
    should("returns a 400") { topic.status }.equals 400
  end

  context "GET /index.xml (atom feed)" do
    setup { @toto.get('/index.xml') }
    asserts("content type is set properly") { topic.content_type }.equals "application/xml"
    asserts("body should be valid xml")     { topic.body }.includes_html("feed > entry" => /.+/)
    asserts("summary shouldn't be empty")   { topic.body }.includes_html("summary" => /.{10,}/)
  end

  context "creating an article" do
    setup do
      @config[:markdown] = true
      @config[:date] = lambda {|t| "the time is #{t.strftime("%Y/%m/%d %H:%M")}" }
      @config[:summary] = {:length => 50}
    end

    context "with the bare essentials" do
      setup do
        Toto::Article.new({
          :title => "Toto & The Wizard of Oz.",
          :body => "#Chapter I\nhello, *stranger*."
        }, @config)
      end

      should("have a title")               { topic.title }.equals "Toto & The Wizard of Oz."
      should("parse the body as markdown") { topic.body }.equals "<h1>Chapter I</h1>\n\n<p>hello, <em>stranger</em>.</p>\n"
      should("create an appropriate slug") { topic.slug }.equals "toto-and-the-wizard-of-oz"
      should("set the date")               { topic.date }.equals "the time is #{Time.now.strftime("%Y/%m/%d %H:%M")}"
      should("create a summary")           { topic.summary == topic.body }
      should("have an author")             { topic.author }.equals AUTHOR
      should("have a path")                { topic.path }.equals Time.now.strftime("/%Y/%m/%d/toto-and-the-wizard-of-oz/")
      should("have a url")                 { topic.url }.equals Time.now.strftime("#{URL}/%Y/%m/%d/toto-and-the-wizard-of-oz/")
    end

    context "with a user-defined summary" do
      setup do
        Toto::Article.new({
          :title => "Toto & The Wizard of Oz.",
          :body => "Well,\nhello ~\n, *stranger*."
        }, @config.merge(:markdown => false, :summary => {:max => 150, :delim => /~\n/}))
      end

      should("split the article at the delimiter") { topic.summary }.equals "Well,\nhello"
      should("not have the delimiter in the body") { topic.body !~ /~/ }
    end

    context "with everything specified" do
      setup do
        Toto::Article.new({
          :title  => "The Wizard of Oz",
          :body   => ("a little bit of text." * 5) + "\n" + "filler" * 10,
          :date   => "19/10/1976",
          :slug   => "wizard-of-oz",
          :author => "toetoe"
        }, @config)
      end

      should("parse the date") { [topic[:date].month, topic[:date].year] }.equals [10, 1976]
      should("use the slug")   { topic.slug }.equals "wizard-of-oz"
      should("use the author") { topic.author }.equals "toetoe"

      context "and long first paragraph" do
        should("create a valid summary") { topic.summary }.equals "<p>" + ("a little bit of text." * 5).chop + "&hellip;</p>\n"
      end

      context "and a short first paragraph" do
        setup do
          @config[:markdown] = false
          Toto::Article.new({:body => "there ain't such thing as a free lunch\n" * 10}, @config)
        end

        should("create a valid summary") { topic.summary.size }.within 75..80
      end
    end
  end
end


