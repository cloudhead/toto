require 'rubygems'
require 'rspec'
require 'capybara'
require 'capybara/rspec'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tinman'

Capybara.app = TinMan::Server.new

