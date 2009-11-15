require 'riot'
require 'hpricot'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'toto'

module Riot
  module AssertionMacros
    def includes(expected)
      actual.include?(expected) || fail("expected #{actual} to include #{expected}")
    end

    def includes_html(expected)
      doc = Hpricot(actual)
      expected = expected.flatten
      !(doc/expected.first).empty? || fail("expected #{actual} to contain a <#{expected.first}>")
      (doc/expected.first).inner_html.match(expected.last) ||
        fail("expected #{actual} to include a <#{expected.first}> element with #{expected.last} inside")
    end

    def within(expected)
      expected.include?(actual) || fail("expected #{actual} to be within #{expected}")
    end
  end
end
