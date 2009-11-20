require 'yaml'
require 'time'
require 'erb'
require 'rack'

require 'rdiscount'
require 'builder'
require 'ext'

module Toto
  Paths = {
    :templates => "templates",
    :pages => "templates/pages",
    :articles => "articles"
  }

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
              Article.new File.read(article), @config
          end }.merge archives
        when :xml, :json
          return :articles => self.articles.map do |article|
            Article.new File.read(article), @config
          end
        else return {}
      end
    end

    def archives filter = //
      entries = ! self.articles.empty??
        self.articles.select do |a|
          File.basename(a) =~ /^#{filter}/
        end.reverse.map do |article|
          Article.new File.read(article), @config
        end : []

      return :archives => Archives.new(entries)
    end

    def article route
      begin
        Article.new File.read("#{Paths[:articles]}/#{route.join('-')}.#{self[:ext]}")
      rescue Errno::ENOENT
        http 401
      end
    end

    def /
      self[:root]
    end

    def go route, type = :html
      route << self./ if route.empty?
      type = type.to_sym

      body, status = if Context.new.respond_to?(:"to_#{type}")
        if route.first =~ /\d{4}/
          case route.size
            when 1..3
              [Context.new(archives(route * '-'), @config).render(:archives, type), 200]
            when 4
              [Context.new(article(route), @config).render(:article, type), 200]
            else http 400
          end
        elsif respond_to?(route = route.first.to_sym)
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
      Dir["#{Paths[:articles]}/*.#{self[:ext]}"]
    end

    class Context
      include Template

      def initialize ctx = {}, config = {}
        @config = config
        ctx.each {|k, v| meta_def(k) { v } }
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
      @config = config

      data = if obj.is_a? String
        meta, self[:body] = obj.split(/\n\n/, 2)
        YAML.load(meta)
      elsif obj.is_a? Hash
        obj
      end.inject({}) {|h, (k,v)| h.merge(k.to_sym => v) }

      self.update data
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
      :ext => 'txt'                                       # extension for articles
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

      response = Toto::Site.new(@config).go(route, *mime)

      @response.body = [response[:body]]
      @response['Content-Length'] = response[:body].length.to_s
      @response['Content-Type']   = Rack::Mime.mime_type(".#{response[:type]}")

      # Cache for one day
      @response['Cache-Control'] = "public, max-age=86400"
      @response['Etag'] = Digest::SHA1.hexdigest(response[:body])

      @response.status = response[:status]
      @response.finish
    end
  end
end

