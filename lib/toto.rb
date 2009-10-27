require 'fileutils'
require 'yaml'
require 'erb'

module Toto
  TEMPLATES = "lib/templates"

  module Template
    def to_html bind = binding
      ERB.new(File.read("#{TEMPLATES}/#{slug}.html")).result(bind)
    end
  end

  module Feed
  end

  class Container
    def slug
      self.class.to_s.split('::').last.downcase
    end

    def render mime = "html"
      case mime
        when "html"
          Layout.new.to_html { self.to_html }
        when "xml"
          self.resource.to_xml
        when "json"
          self.resource.to_json
        else raise ArgumentError
      end
    end
  end

  class Layout < Container
    include Template
    attr_accessor :title
    def initialize
      @title = Dir.pwd
    end
  end

  class Home < Container
    include Template
    include Feed
    attr_reader :articles

    def initialize
      @articles = Dir['articles/*.txt'].map do |article|
        data = File.read(article).split(/\n\n/, 2)
        Article.new({:content => data.last.strip}.merge(YAML.load(data.first)))
      end
    end

    alias :resource :articles
  end

  class Resource
    attr_reader :data

    def initialize data = {}
      # Serialize keys
      @data = data.inject({}) {|h, (k,v)| h.merge(k.to_sym => v) }
    end

    def method_missing m, *args, &blk
      @data.keys.include?(m) ? @data[m] : super
    end
  end

  class Article < Resource
  end

  class Server
    def call env
      @request  = Rack::Request.new env
      @response = Rack::Response.new

      path, mime = @request.path_info.split('.')
      page, key = path.split('/').reject {|i| i.empty? }
      page ||= "home"
      mime ||= "html"

      @response.body = [Toto.const_get(page.capitalize).new.render(mime)]
      @response['Content-Length'] = @response.body.first.length.to_s
      @response.status = 200
      @response.finish
    end
  end
end
