require 'yaml'
require 'time'
require 'erb'
require 'rack'
require 'digest'

require 'rdiscount'
require 'builder'

$:.unshift File.dirname(__FILE__)

require 'ext/ext'

module Toto
  Paths = {
    :templates => "templates",
    :pages => "templates/pages",
    :articles => "articles"
  }

  def self.env
    ENV['RACK_ENV'] || 'production'
  end

  def self.env= env
    ENV['RACK_ENV'] = env
  end

  module Template
    def to_html page, &blk
      path = (page == :layout ? Paths[:templates] : Paths[:pages])
      ERB.new(File.read("#{path}/#{page}.rhtml")).result(binding)
    end

    def self.included obj
      obj.class_eval do
        define_method(obj.to_s.split('::').last.downcase) { self }
      end
    end
  end

  class Site
    def initialize config
      @config = config
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
          {:articles => self.articles.reverse.map do |article|
              Article.new File.new(article), @config
          end }.merge archives
        when :xml, :json
          return :articles => self.articles.map do |article|
            Article.new File.new(article), @config
          end
        else return {}
      end
    end

    def archives filter = ""
      entries = ! self.articles.empty??
        self.articles.select do |a|
          filter !~ /^\d{4}/ || File.basename(a) =~ /^#{filter}/
        end.reverse.map do |article|
          Article.new File.new(article), @config
        end : []

      return :archives => Archives.new(entries)
    end

    def article route
      Article.new(File.new("#{Paths[:articles]}/#{route.join('-')}.#{self[:ext]}"), @config).load
    end

    def /
      self[:root]
    end

    def go route, type = :html
      route << self./ if route.empty?
      type, path = type.to_sym, route.join('/')

      body, status = if Context.new.respond_to?(:"to_#{type}")
        if route.first =~ /\d{4}/
          case route.size
            when 1..3
              Context.new(archives(route * '-'), @config, path).render(:archives, type)
            when 4
              Context.new(article(route), @config, path).render(:article, type)
            else http 400
          end
        elsif respond_to?(route = route.first.to_sym)
          Context.new(send(route, type), @config, path).render(route, type)
        else
          Context.new({}, @config, path).render(route.to_sym, type)
        end
      else
        http 400
      end

    rescue Errno::ENOENT => e
      return :body => http(404).first, :type => :html, :status => 404
    else
      return :body => body || "", :type => type, :status => status || 200
    end

  protected

    def http code
      return ["<font style='font-size:300%'>toto, we're not in Kansas anymore (#{code})</font>", code]
    end

    def articles
      self.class.articles self[:ext]
    end

    def self.articles ext
      Dir["#{Paths[:articles]}/*.#{ext}"]
    end

    class Context
      include Template

      def initialize ctx = {}, config = {}, path = "/"
        @config, @context, @path = config, ctx, path
        @articles = Site.articles(@config[:ext]).reverse.map do |a|
          Article.new(File.new(a), @config)
        end

        ctx.each do |k, v|
          meta_def(k) { ctx.instance_of?(Hash) ? v : ctx.send(k) }
        end
      end

      def title
        @config[:title]
      end

      def render page, type
        type == :html ? to_html(:layout, &Proc.new { to_html page }) : send(:"to_#{type}", :feed)
      end

      def to_xml page
        xml = Builder::XmlMarkup.new(:indent => 2)
        instance_eval File.read("#{Paths[:templates]}/#{page}.builder")
      end
      alias :to_atom to_xml

      def method_missing m, *args, &blk
        @context.respond_to?(m) ? @context.send(m) : super
      end
    end
  end

  class Archives < Array
    include Template

    def initialize articles
      self.replace articles
    end

    def to_html
      super(:archives)
    end
    alias :to_s to_html
    alias :archive archives
  end

  class Article < Hash
    include Template

    def initialize obj, config = {}
      @obj, @config = obj, config
      self.load if obj.is_a? Hash
    end

    def load
      data = if @obj.is_a? File
        meta, self[:body] = @obj.read.split(/\n\n/, 2)
        YAML.load(meta)
      elsif @obj.is_a? Hash
        @obj
      end.inject({}) {|h, (k,v)| h.merge(k.to_sym => v) }

      self.taint
      self.update data
      self[:date] = Time.parse(self[:date].gsub('/', '-')) rescue Time.now
      self
    end

    def [] key
      self.load unless self.tainted?
      super
    end

    def slug
      self[:slug] || self[:title].slugize
    end

    def summary length = nil
      config = @config[:summary]
      sum = if self[:body] =~ config[:delim]
        self[:body].split(config[:delim]).first
      else
        self[:body].match(/(.{1,#{length || config[:length]}}.*?)(\n|\Z)/m).to_s
      end
      markdown(sum.length == self[:body].length ? sum : sum.strip.sub(/\.\Z/, '&hellip;'))
    end

    def url
      "http://#{(@config[:url].sub("http://", '') + self.path).squeeze('/')}"
    end
    alias :permalink url

    def body
      markdown self[:body].sub(@config[:summary][:delim], '') rescue markdown self[:body]
    end

    def title()   self[:title] || "an article"               end
    def date()    @config[:date, self[:date]]                end
    def path()    self[:date].strftime("/%Y/%m/%d/#{slug}/") end
    def author()  self[:author] || @config[:author]          end
    def to_html() self.load; super(:article)                 end

    alias :to_s to_html

    def method_missing m, *args, &blk
      self.keys.include?(m) ? self[m] : super
    end

  private

    def markdown text
      if (options = @config[:markdown])
        Markdown.new(text.to_s.strip, *(options.eql?(true) ? [] : options)).to_html
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
      :url => "http://127.0.0.1",
      :date => lambda {|now| now.strftime("%d/%m/%Y") },  # date function
      :markdown => :smart,                                # use markdown
      :disqus => false,                                   # disqus name
      :summary => {:max => 150, :delim => /~\n/},         # length of summary and delimiter
      :ext => 'txt',                                      # extension for articles
      :cache => 28800                                     # cache duration (seconds)
    }
    def initialize obj
      self.update Defaults
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

    def initialize config = {}, &blk
      @config = config.is_a?(Config) ? config : Config.new(config)
      @config.instance_eval(&blk) if block_given?
    end

    def call env
      @request  = Rack::Request.new env
      @response = Rack::Response.new

      return [400, {}, []] unless @request.get?

      path, mime = @request.path_info.split('.')
      route = path.split('/').reject {|i| i.empty? }

      response = Toto::Site.new(@config).go(route, *(mime ? mime : []))

      @response.body = [response[:body]]
      @response['Content-Length'] = response[:body].length.to_s unless response[:body].empty?
      @response['Content-Type']   = Rack::Mime.mime_type(".#{response[:type]}")

      # Set http cache headers
      @response['Cache-Control'] = if Toto.env == 'production'
        "public, max-age=#{@config[:cache]}"
      else
        "no-cache, must-revalidate"
      end

      @response['Etag'] = Digest::SHA1.hexdigest(response[:body])

      @response.status = response[:status]
      @response.finish
    end
  end
end

