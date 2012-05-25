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
  system("rake test VERBOSE=true")
end

#
# Watchr Rules
#
watch('^test/.*?_test\.rb'   ) { run_all_tests }
watch('^lib/(.*)\.rb'        ) { run_all_tests }
watch('^lib/toto/(.*)\.rb'   ) { run_all_tests }
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
