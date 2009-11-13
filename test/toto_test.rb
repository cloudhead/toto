require 'test/test_helper'

context Toto do
  setup do
    config = {:url => "http://toto.oz"}
    @toto = Rack::MockRequest.new(Toto::Server.new(config))
    Toto::Paths[:articles] = "test/articles"
    Toto::Paths[:pages] = "test/templates"
    Toto::Paths[:templates] = "test/templates"
  end

  context "GET /" do
    setup { @toto.get('/') }

    asserts("returns a 200")                { topic.status          }.equals 200
    asserts("body is not empty")            { not topic.body.empty? }
    asserts("content type is set properly") { topic.content_type    }.equals "text/html"
    should("include an article")            { topic.body            }.includes_html("#articles" => /Once upon a time/)
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
    asserts("body should be valid xml")     { topic.body         }.includes_html("feed > entry" => /.+/)
    asserts("summary shouldn't be empty")   { topic.body         }.includes_html("summary" => /.{10,}/)
  end
end

