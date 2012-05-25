# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{toto}
  s.version = "0.4.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["jbrains", "cloudhead"]
  s.date = %q{2011-07-07}
  s.description = %q{the tiniest blog-engine in Oz, now with Canadian flair!}
  s.email = %q{me@jbrains.ca}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "TODO"
  ]
  s.files = [
    ".autotest",
    ".document",
    ".rspec",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "TODO",
    "VERSION",
    "lib/ext/ext.rb",
    "lib/toto.rb",
    "spec/photo_article_spec.rb",
    "test/articles/1900-05-17-the-wonderful-wizard-of-oz.txt",
    "test/articles/2001-01-01-two-thousand-and-one.txt",
    "test/articles/2009-04-01-tilt-factor.txt",
    "test/articles/2009-12-04-some-random-article.txt",
    "test/articles/2009-12-11-the-dichotomy-of-design.txt",
    "test/articles/2011-06-30-a-model-for-improving-names.txt",
    "test/autotest.rb",
    "test/templates/about.rhtml",
    "test/templates/archives.rhtml",
    "test/templates/article.rhtml",
    "test/templates/feed.builder",
    "test/templates/index.builder",
    "test/templates/index.rhtml",
    "test/templates/layout.rhtml",
    "test/templates/repo.rhtml",
    "test/test_helper.rb",
    "test/toto_test.rb",
    "toto.gemspec"
  ]
  s.homepage = %q{http://github.com/jbrains/toto}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{the tiniest blog-engine in Oz, now with Canadian flair}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<hpricot>, [">= 0"])
      s.add_development_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<rdiscount>, [">= 0"])
      s.add_development_dependency(%q<builder>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<hpricot>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<rdiscount>, [">= 0"])
      s.add_dependency(%q<builder>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<hpricot>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<rdiscount>, [">= 0"])
    s.add_dependency(%q<builder>, [">= 0"])
  end
end

