require 'toto'
require 'nokogiri'

describe "Rendering an article that displays a photo" do
  AUTHOR = "J. B. Rainsberger"
  URL = "http://www.jbrains.ca"

  before(:each) do
    @config = Toto::Config.new(:markdown => true, :author => AUTHOR, :url => URL)
    @toto = Rack::MockRequest.new(Toto::Server.new(@config))
    Toto::Paths[:articles] = "test/articles"
    Toto::Paths[:pages] = "test/templates"
    Toto::Paths[:templates] = "test/templates"
  end

  context "by setting an article type" do
    it "should use the photo template" do
      pending "Figuring out how to instantiate an Article"
      topic = @toto.get('/2011/06/30/a-model-for-improving-names')

      topic.status.should == 200
      topic.content_type.should == "text/html"
      html = Nokogiri::HTML(topic.body)
      html.at_css("h2").content.should == "A model for improving names"
      html.at_css("span").content.should == "30/06/2011"
      html.at_css("img").should_not be_nil
      html.at_css("img")["src"].should == "http://30.media.tumblr.com/tumblr_lmsovxnwmq1qa6fh7o1_500.png"
      image_div = html.at_css("div#image")
      image_div.at_css("img/src").should == "http://30.media.tumblr.com/tumblr_lmsovxnwmq1qa6fh7o1_500.png"

#<div id="image"><a href="<%= image_clickthrough_url %>"><img src="<%= image_src %>"></img></a></div>
    end
  end
end

describe "What kind of Article does Toto create?" do
  before(:each) do
    @config = Toto::Config.new(:markdown => true, :author => AUTHOR, :url => URL)
    @toto = Rack::MockRequest.new(Toto::Server.new(@config))
    Toto::Paths[:articles] = "test/articles"
  end

  context "when loading an article with extra metadata in it" do
    it "exposes the metadata as methods" do
      @site = Toto::Site.new(@config)
      @article = @site.article("2011/06/30/a-model-for-improving-names".split("/"))
      @article.image.should == "http://30.media.tumblr.com/tumblr_lmsovxnwmq1qa6fh7o1_500.png"
    end
  end
end
