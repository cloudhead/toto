require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "glinda"
    gem.summary = %Q{Toto, expanded}
    gem.description = %Q{Toto, expanded}
    gem.email = "ryan@slingingcode.com"
    gem.homepage = "http://github.com/rschmukler/glinda"
    gem.authors = ["rschmukler"]
    gem.add_development_dependency "rspec"
    gem.add_dependency "builder"
    gem.add_dependency "rack"
    if RUBY_PLATFORM =~ /win32/
      gem.add_dependency "maruku"
    else
      gem.add_dependency "rdiscount"
    end
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
