`include "svunit_defines.svh"
`include "svlib_Str_pkg.sv"

module Str_unit_test;

  import svunit_pkg::*;
  import svlib_Str_pkg::*;

  string name = "Str_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  Str my_Str;


  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);

    my_Str = new(/* New arguments if needed */);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */
  endtask


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */
  endtask


  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN
  
  `SVTEST(Str_create_check)
    string test_str;
    test_str = "";
    `FAIL_IF(my_Str.get() != test_str)
    test_str = "hello world";
    my_Str = Str::create(test_str);
    `FAIL_IF(my_Str.get() != test_str)
    test_str = "bye";
    my_Str.set(test_str);
    `FAIL_IF(my_Str.get() != test_str)
  `SVTEST_END



  `SVUNIT_TESTS_END

endmodule
