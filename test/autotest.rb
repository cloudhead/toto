#
# Convenience Methods
#
def run(cmd)
  print "\n\n"
  puts(cmd)
  system(cmd)
  print "\n\n"
end

def run_all_tests
  # see Rakefile for the definition of the test:all task
  system("rake -s test:all VERBOSE=true")
end

#
# Watchr Rules
#
watch('^test/.*?_test\.rb'   ) {|m| run("ruby -rubygems %s"              % m[0]) }
watch('^lib/(.*)\.rb'        ) {|m| run("ruby -rubygems test/%s_test.rb" % m[1]) }
watch('^lib/toto/(.*)\.rb'   ) {|m| run("ruby -rubygems test/%s_test.rb" % m[1]) }
watch('^test/test_helper\.rb') { run_all_tests }

#
# Signal Handling
#
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }
