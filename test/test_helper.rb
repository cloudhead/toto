require 'rubygems'
require 'hpricot'
require 'riot'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'toto'

module Riot
  class Assertion
    assertion(:includes) do |actual, expected|
      actual.include?(expected) ? pass : fail("expected #{actual} to include #{expected}")
    end

    assertion(:includes_html) do |actual, expected|
      doc = Hpricot.parse(actual)
      expected = expected.to_a.flatten

      if (doc/expected.first).empty?
        fail("expected #{actual} to contain a <#{expected.first}>")
      elsif !(doc/expected.first).inner_html.match(expected.last)
        fail("expected <#{expected.first}> to contain #{expected.last}")
      else
        pass
      end
    end

    assertion(:includes_elements) do |actual, selector, count|
      doc = Hpricot.parse(actual)
      (doc/selector).size == count ? pass : fail("expected #{actual} to contain #{count} #{selector}(s)")
    end

    assertion(:within) do |actual, expected|
      expected.include?(actual) ? pass : fail("expected #{actual} to be within #{expected}")
    end
  end
end
