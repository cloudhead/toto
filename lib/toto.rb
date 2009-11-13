require 'yaml'
require 'time'
require 'erb'
require 'rack'
require 'ostruct'

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
    def to_html page, bind = binding, &blk
      ERB.new(File.read("#{Paths[:pages]}/#{page}.rhtml")).result(binding)
    end
  end

  class Site
    include Template

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

    def index type
      case type
        when :html
          return :articles => self.articles.reverse[0...self[:paginate]].map do |article|
            Article.new File.read(article), @config
          end
        when :xml, :json
          return self.articles.map do |article|
            Article.new File.read(article), @config
          end
        else return {}
      end
    end

    def archive
      return :archive => self.articles.reverse[self[:paginate]..-1].map do |article|
        Article.new File.read(article), @config
      end
    end

    def /
      self[:root]
    end

    def go route, method, type = "html"
      route ||= self./

      body, status = if respond_to?(:"to_#{type}") && method == :GET
        if respond_to?(route)
          render = Proc.new do
            send(route.to_sym, type.to_sym).each {|k,v| meta_def(k) { v } }
            self.to_html(route)
          end

          [type == "html" ? send(:to_html, :layout, binding, &render)
                          : send(:"to_#{type}", self.index(type.to_sym)), 200]
        else
          http 401
        end
      else
        http 400
      end

      return :body => body, :type => type, :status => status
    end

    def to_xml articles
      xml = Builder::XmlMarkup.new(:indent => 2)
      instance_eval File.read("#{Paths[:templates]}/feed.builder")
    end
    alias :to_atom to_xml

  protected

    def http code
      return ["HTTP #{code}", code]
    end

    def articles
      Dir["#{Paths[:articles]}/*.txt"]
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
      markdown self[:body].match(/(.{#{length}}.*?)(\n|\Z)/m) || self[:body]
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
        Markdown.new(text.strip, *(markdown unless markdown.eql?(true))).to_html
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

    def []= key, val
      super
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
      @config = Config.new(config)
    end

    def call env
      @request  = Rack::Request.new env
      @response = Rack::Response.new

      method = @request.request_method.to_sym
      path, mime = @request.path_info.split('.')
      page, key = path.split('/').reject {|i| i.empty? }

      response = Toto::Site.new(@config).go(page, method, *mime)

      @response.body = [response[:body]]
      @response['Content-Length'] = response[:body].length.to_s
      @response['Content-Type'  ] = Rack::Mime.mime_type(".#{response[:type]}")
      @response.status = response[:status]
      @response.finish
    end
  end
end

