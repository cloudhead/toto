require 'rubygems'
require 'hpricot'
require 'riot'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'toto'

module Toto
  class IncludesHTMLMacro < Riot::AssertionMacro
    register :includes_html

    def evaluate(actual, expected)
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
  end

  class IncludesElementsMacro < Riot::AssertionMacro
    register :includes_elements

    def evaluate(actual, selector, count)
      doc = Hpricot.parse(actual)
      (doc/selector).size == count ? pass : fail("expected #{actual} to contain #{count} #{selector}(s)")
    end
  end

  class WithinMacro < Riot::AssertionMacro
    register :within

    def evaluate(actual, expected)
      expected.include?(actual) ? pass : fail("expected #{actual} to be within #{expected}")
    end
  end
end
