my_tests = ["test_cmplot.jl"]

println("Running tests:")
for my_test in my_tests
  include(my_test)
end
