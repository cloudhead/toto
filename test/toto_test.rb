require 'test/test_helper'

URL = "http://toto.oz"
AUTHOR = "toto"

context Toto do
  setup do
    @config = Toto::Config.new({:author => AUTHOR, :url => URL})
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
    should("include an article")            { topic.body }.includes_html("#articles" => /Once upon a time/)
  end

  context "GET to an unknown route" do
    setup { @toto.get('/unknown') }
    should("returns a 401") { topic.status }.equals 401
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
      @config[:date] = lambda {|t| "the time is #{t}" }
      @config[:summary] = 50
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
      should("set the date")               { topic.date }.equals "the time is #{Time.now}"
      should("create a summary")           { topic.summary == topic.body }
      should("have an author")             { topic.author }.equals AUTHOR
      should("have a path")                { topic.path }.equals Time.now.strftime("/%Y/%m/%d/toto-and-the-wizard-of-oz/")
      should("have a url")                 { topic.url }.equals Time.now.strftime("#{URL}/%Y/%m/%d/toto-and-the-wizard-of-oz/")
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
        should("create a valid summary") { topic.summary }.equals "<p>" + "a little bit of text." * 5 + "</p>\n"
      end

      context "and a short first paragraph" do
        setup do
          @config[:markdown] = false
          Toto::Article.new({:body => "there ain't such thing as a free lunch\n" * 10}, @config)
        end

        should("create a valid summary") { topic.summary.size }.within (75..80)
      end
    end
  end
end


