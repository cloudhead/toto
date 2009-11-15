require 'yaml'
require 'time'
require 'erb'
require 'rack'

require 'rdiscount'
require 'builder'
require 'ext'

module Toto
  Paths = {
    :config => "config/config.rb",
    :templates => "templates",
    :pages => "templates/pages"
  }

  module Template
    def to_html page, &blk
      ERB.new(File.read("#{Paths[:pages]}/#{page}.rhtml")).result(binding)
    end
  end

  class Site
    def initialize config
      @config = config
      @title = self[:title]
    end

    def [] *args
      @config[*args]
    end

    def []= key, value
      @config.set key, value
    end

    def index type = :html
      case type
        when :html
          return :articles => self.articles.reverse[0...self[:paginate]].map do |article|
            Article.new File.read(article), @config
          end
        when :xml, :json
          return :articles => self.articles.map do |article|
            Article.new File.read(article), @config
          end
        else return {}
      end
    end

    def archives count = self[:paginate]
      return :archives => self.articles.reverse[count..-1].map do |article|
        Article.new File.read(article), @config
      end
    end

    def /
      self[:root]
    end

    def go route, type = :html
      route ||= self./
      route, type = route.to_sym, type.to_sym

      body, status = if Context.new.respond_to?(:"to_#{type}")
        if respond_to?(route)
          [Context.new(send(route, type), @config).render(route, type), 200]
        else
          http 401
        end
      else
        http 400
      end

      return :body => body, :type => type, :status => status
    end

  protected

    def http code
      return ["HTTP #{code}", code]
    end

    def articles
      Dir["#{Paths[:articles]}/*.txt"]
    end

    class Context
      include Template

      def initialize ctx = {}, config = {}
        @config = config

        ctx.each do |k, v|
          if v.is_a? Proc
            meta_def(k, &v)
          else
            meta_def(k) { v }
          end
        end
      end

      def render page, type
        type == :html ? to_html(:layout, &Proc.new { to_html page }) : send(:"to_#{type}", :feed)
      end

      def to_xml page
        xml = Builder::XmlMarkup.new(:indent => 2)
        instance_eval File.read("#{Paths[:templates]}/#{page}.builder")
      end
      alias :to_atom to_xml
    end
  end

  class Article < Hash
    include Template

    def initialize str, config = {}
      @config = config
      meta, self[:body] = str.split(/\n\n/, 2)
      self.update YAML.load(meta).inject({}) {|h, (k,v)| h.merge(k.to_sym => v) }
      self[:date] = Time.parse(self[:date]) rescue Time.now
    end

    def slug
      self[:slug] ||
      self[:title].downcase.gsub(/&/, 'and').gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '')
    end

    def summary length = @config[:summary]
      markdown self[:body].match(/(.{1,#{length}}.*?)(\n|\Z)/m).to_s
    end

    def body()    markdown self[:body]                       end
    def url()     @config[:url] + self.path                  end
    def date()    @config[:date, self[:date]]                end
    def path()    self[:date].strftime("/%Y/%m/%d/#{slug}/") end
    def author()  self[:author] || @config[:author]          end
    def to_html() super(:article)                            end

    alias :to_s to_html

    def method_missing m, *args, &blk
      self.keys.include?(m) ? self[m] : super
    end

  private

    def markdown text
      if (markdown = @config[:markdown])
        Markdown.new(text.to_s.strip, *(markdown unless markdown.eql?(true))).to_html
      else
        text.strip
      end
    end
  end

  class Config < Hash
    Defaults = {
      :author => ENV['USER'],                             # blog author
      :title => Dir.pwd.split('/').last,                  # site title
      :root => "index",                                   # site index
      :date => lambda {|now| now.strftime("%d/%m/%Y") },  # date function
      :markdown => :smart,                                # use markdown
      :disqus => false,                                   # disqus name
      :summary => 150,                                    # length of summary
      :paginate => 10                                     # number of articles in index
    }
    def initialize obj
      self.update Defaults

      if File.exist?(Paths[:config])
        instance_eval { load Paths[:config] }
      end

      self.update obj
    end

    alias set :[]=

    def [] key, *args
      val = super(key)
      val.respond_to?(:call) ? val.call(*args) : val
    end
  end

  class Server
    attr_reader :config

    def initialize config = {}
      @config = config.is_a?(Config) ? config : Config.new(config)
    end

    def call env
      @request  = Rack::Request.new env
      @response = Rack::Response.new

      method = @request.request_method.to_sym
      path, mime = @request.path_info.split('.')
      page, key  = path.split('/').reject {|i| i.empty? }

      response = Toto::Site.new(@config).go(page, method, *mime)

      @response.body = [response[:body]]
      @response['Content-Length'] = response[:body].length.to_s
      @response['Content-Type']   = Rack::Mime.mime_type(".#{response[:type]}")
      @response.status = response[:status]
      @response.finish
    end
  end
end

