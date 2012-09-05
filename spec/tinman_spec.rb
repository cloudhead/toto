require 'spec_helper'
require 'date'

URL = "http://toto.oz"
AUTHOR = "TinMan"

include Capybara::DSL
include Capybara::RSpecMatchers

describe TinMan do
  before(:each) do
    @config = TinMan::Config.new(:markdown => true, :author => AUTHOR, :url => URL)
    @tinman = Rack::MockRequest.new(TinMan::Server.new(@config))
    TinMan::Paths[:articles] = "spec/articles"
    TinMan::Paths[:pages] = "spec/templates"
    TinMan::Paths[:templates] = "spec/templates"
  end

  describe "GET /" do
    let(:response) { @tinman.get('/') }

    it "should return status code 200" do
      response.status.should == 200
    end

    it "should not have an empty body" do
      response.body.should_not be_empty
    end

    it "should set the content-type" do
      response.content_type.should == "text/html"
    end

    it "should include 2 articles" do
      visit '/'
      page.all('#articles li').count.should == 3
    end

    it "should include an archive" do
      visit '/'
      page.all('#archives li').count.should == 2
    end

    context "with no articles" do
      let(:response) { Rack::MockRequest.new(TinMan::Server.new(@config.merge(:ext => 'oxo'))).get('/') }

      it "should return status code 200" do
        response.status.should == 200
      end

      it "should not have an empty body" do
        response.body.should_not be_empty
      end
    end

    context "with a user-defined to_html" do
      let(:response) do
        @config[:to_html] = lambda do |path, page, binding|
          ERB.new(File.read("#{path}/#{page}.rhtml")).result(binding)
        end
        @tinman.get('/')
      end

      it "should return status code 200" do
        response.status.should == 200
      end

      it "should not have an empty body" do
        response.body.should_not be_empty
      end

      it "should set the content-type" do
        response.content_type.should == "text/html"
      end

      it "should include 2 articles" do
        visit '/'
        page.all('#articles li').count.should == 3
      end

      it "should include an archive" do
        visit '/'
        page.all('#archives li').count.should == 2
      end

      it "should set Etag header" do
        response.headers.should include "ETag"
      end

      it "should set the ETag value" do
        response.headers["ETag"].should_not be_empty
      end
    end
  end

  context "GET /about" do
    let(:response) { @tinman.get('/about') }
    it "should return status code 200" do
      response.status.should == 200
    end

    it "should not have an empty body" do
      response.body.should_not be_empty
    end

    it "should set the content-type" do
      response.content_type.should == "text/html"
    end

    it "should have access to @articles" do
      visit '/about'
      page.find('#count').should have_content '5'
    end
  end

  context "GET a single article" do
    let(:response) { @tinman.get("/1900/05/17/the-wonderful-wizard-of-oz") }

    it "should return status code 200" do
      response.status.should == 200
    end

    it "should include the article" do
      visit '/1900/05/17/the-wonderful-wizard-of-oz'
      page.should have_content "Once upon a time"
    end


    it "should set the content-type" do
      response.content_type.should == "text/html"
    end
  end

  context "GET to the archive" do
    context "through a year" do
      before(:each) { visit '/2009' }

      it "should return a 200" do
        page.status_code.should == 200
      end

      it "should return the articles for that year" do
        page.all('li.entry').count.should == 3
      end
    end

    context "through a year & month" do
      before(:each) { visit '/2009/12' }

      it "should return a 200" do
        page.status_code.should == 200
      end

      it "should return the articles for that year" do
        page.all('li.entry').count.should == 2
      end

      it "should include the year and month" do
        page.find("h1").should have_content("2009/12")
      end
    end
  end

  context "GET to an unknown route with a custom error" do
    before(:each) do
      @config[:error] = lambda {|code| "error: #{code}" }
      Capybara.app = TinMan::Server.new(@config)
      visit('/unknown')
    end

    it "should return a 404" do
      page.status_code.should == 404
    end

    it "should display the custom error" do
      page.should have_content "error: 404"
    end
  end

  context "Request is invalid" do
    let(:response) { @tinman.delete('/invalid') }
    it "should return status code 400" do
      response.status.should == 400
    end
  end

  context "GET /index.xml (atom feed)" do
    before(:each) do
      visit '/index.xml'
    end

    it "should set content-type" do
      page.response_headers['content-type'].should == 'application/xml'
    end

    it "be valid xml" do
      page.all('feed entry').count.should > 0
    end

    it "should show a summary" do
      page.should have_css 'feed entry summary'
    end
  end

  context "GET /index?param=testparam (get parameter)" do
    before :each do
      visit 'index?param=testparam'
    end

    it "should return status code 200" do
      page.status_code.should == 200
    end

    it "set content-type properly" do
      page.response_headers['content-type'].should == 'text/html'
    end

    it "contain the env variable" do
      page.should have_content 'env passed: true'
    end

    it "be able to access the HTTP GET Param" do
      page.should have_content 'request method type: GET'
    end

    it "should access the http paramiter name value pair" do
      page.should have_content 'request name value pair: param=testparam'
    end
  end



  context "GET to a repo name" do
    before(:all) do
      class TinMan::Repo
        def readme() "#{self[:name]}'s README" end
      end
    end

    context "when the repo is in the :repos array" do
      before(:each) do
        @config[:github] = {:user => "cloudhead", :repos => ['the-repo']}
        Capybara.app = TinMan::Server.new(@config)
        visit '/the-repo'
      end
      it "should return the repo README" do
        page.should have_content "the-repo's README"
      end
    end

    context "when the repo is not in the :repos array" do
      before :each do
        @config[:github] = {:user => "cloudhead", :repos => []}
        Capybara.app = TinMan::Server.new(@config)
        visit '/the-repo'
      end

      it "should return a 404" do
        page.status_code.should == 404
      end
    end
  end

  context "creating an article" do
    before(:each) do
      @config[:markdown] = true
      @config[:date] = lambda {|t| "the time is #{t.strftime("%Y/%m/%d %H:%M")}" }
      @config[:summary] = {:length => 50}
      Capybara.app = TinMan::Server.new(@config)
    end

    context "with the bare essentials" do

      let(:article) { TinMan::Article.new({ title: "TinMan & The Wizard of Oz.", body: "#Chapter I\nHello, *stranger*." }, @config) }

      it { article.title.should == "TinMan & The Wizard of Oz." }
      it "should parse the body as markdown" do
        article.body.should == "<h1>Chapter I</h1>\n\n<p>Hello, <em>stranger</em>.</p>\n"
      end

      it "should create the appropriate slug" do
        article.slug.should == "tinman-and-the-wizard-of-oz"
      end

      it "should set the date" do
        article.date.should == "the time is #{Date.today.strftime("%Y/%m/%d %H:%M")}"
      end

      it "should create a summary" do
        article.summary.should == article.body
      end

      it "should have an author" do
        article.author.should == AUTHOR
      end

      it "should have a path" do
        article.path.should == Date.today.strftime("/%Y/%m/%d/tinman-and-the-wizard-of-oz/")
      end

      it "should have a URL" do
        article.url.should == Date.today.strftime("#{URL}/%Y/%m/%d/tinman-and-the-wizard-of-oz/")
      end
    end

    context "with a user-defined summary" do
      let(:article) do
        TinMan::Article.new({
          :title => "TinMan & The Wizard of Oz.",
          :body => "Well,\nhello ~\n, *stranger*."
        }, @config.merge(:markdown => false, :summary => {:max => 150, :delim => /~\n/}))
      end

      it "should split the article at the delmiter" do
        article.summary.should == "Well,\nhello"
      end

      it "should not have the delimiter in the body" do
        article.body. !~ /~/
      end
    end

    context "with everything specified" do
      let(:article) do
        TinMan::Article.new({
          :title  => "The Wizard of Oz",
          :body   => ("a little bit of text." * 5) + "\n" + "filler" * 10,
          :date   => "19/10/1976",
          :slug   => "wizard-of-oz",
          :author => "toetoe"
        }, @config)
      end

      it "should parse the date" do
        article[:date].month.should == 10
        article[:date].year.should == 1976
      end

      it "should use the slug" do
        article.slug.should == "wizard-of-oz"
      end

      it "should use the author" do
        article.author.should == "toetoe"
      end


      context "and long first paragraph" do
        it "should create a valid summary" do
          article.summary.should == "<p>" + ("a little bit of text." * 5).chop + "&hellip;</p>\n"
        end
      end

      context "and a short first paragraph" do
        let(:article) do
          @config[:markdown] = false
          TinMan::Article.new({:body => "there ain't such thing as a free lunch\n" * 10}, @config)
        end

        it "should create a valid summary" do
          article.summary.size.should <= 80
          article.summary.size.should >= 75
        end
      end
    end

    context "in a subdirectory" do
      context "with implicit leading forward slash" do
        let(:article) do
          conf = TinMan::Config.new({})
          conf.set(:prefix, "blog")
          TinMan::Article.new({
            :title => "TinMan & The Wizard of Oz.",
            :body => "#Chapter I\nhello, *stranger*."
          }, conf)
        end

        it "should be in the directory" do
          article.path.should == Date.today.strftime("/blog/%Y/%m/%d/tinman-and-the-wizard-of-oz/")
        end

      end

      context "with explicit leading forward slash" do
        let(:article) do
          conf = TinMan::Config.new({})
          conf.set(:prefix, "/blog")
          TinMan::Article.new({
            :title => "TinMan & The Wizard of Oz.",
            :body => "#Chapter I\nhello, *stranger*."
          }, conf)
        end

        it "should be in the directory do" do
          article.path.should == Date.today.strftime("/blog/%Y/%m/%d/tinman-and-the-wizard-of-oz/")
        end
      end

      context "with explicit trailing forward slash" do
        let(:article) do
          conf = TinMan::Config.new({})
          conf.set(:prefix, "blog/")
          TinMan::Article.new({
            :title => "TinMan & The Wizard of Oz.",
            :body => "#Chapter I\nhello, *stranger*."
          }, conf)
        end

        it "should be in the directory do" do
          article.path.should == Date.today.strftime("/blog/%Y/%m/%d/tinman-and-the-wizard-of-oz/")
        end
      end
    end
  end

  context "using Config#set with a hash" do
    let(:conf) do
      conf = TinMan::Config.new({})
      conf.set(:summary, {:delim => /%/})
      conf
    end

    it "should set summary delim to /%/" do
      conf[:summary][:delim].source.should == "%"
    end

    it "should leave :max intact" do
      conf[:summary][:max].should == 150
    end
  end

  context "using Config#set with a block" do
    let(:conf) do
      conf = TinMan::Config.new({})
      conf.set(:to_html) {|path, p, _| path + p }
      conf
    end

    subject { conf[:to_html] }

    it { should respond_to :call }
  end

  context "testing individual configuration parameters" do
    context "generate error pages" do
      let(:conf) do
        conf = TinMan::Config.new({})
        conf.set(:error) {|code| "error code #{code}" }
        conf
      end

      it "should create an error" do
        conf[:error].call(400).should == "error code 400"
      end

    end
  end

  context "extensions to the core Ruby library" do
    it "should respond to iso8601" do
      Date.today.should respond_to :iso8601
    end
  end
end


