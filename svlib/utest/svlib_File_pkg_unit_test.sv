`include "svunit_defines.svh"

`include "svlib_pkg.sv"

module File_unit_test;

  import svunit_pkg::*;
  import svlib_pkg::*;

  string name = "File_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  Pathname my_PN;

  string test_str;

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);

    my_PN = Pathname::create(/* New arguments if needed */);
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
  
  `SVTEST(File_create_check)

    my_PN.set("/a/b/c/d///e");
    `FAIL_UNLESS_STR_EQUAL(my_PN.get(), "/a/b/c/d/e")
    `FAIL_UNLESS_EQUAL(my_PN.isAbsolute(), 1)
    my_PN.set(my_PN.tail(4));
    `FAIL_UNLESS_STR_EQUAL(my_PN.get(), "b/c/d/e")
    `FAIL_UNLESS_EQUAL(my_PN.isAbsolute(), 0)
    
    
  `SVTEST_END

  `SVTEST(File_append_check)

    my_PN.append("f//g//");
    `FAIL_UNLESS_STR_EQUAL(my_PN.get(), "b/c/d/e/f/g")
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(), "b/c/d/e/f");
    `FAIL_UNLESS_STR_EQUAL(my_PN.extension(), "")
    
    my_PN.append("/q/r/stuff.it///");
    `FAIL_UNLESS_STR_EQUAL(my_PN.get(), "/q/r/stuff.it")
    
  `SVTEST_END

  `SVTEST(File_tail_extn_check)

    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(), "stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(2), "r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(3), "q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(4), "/q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(5), "/q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.extension(), ".it")

    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(), "/q/r");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(2), "/q");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(3), "/");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(4), "/");
    
    my_PN.set(my_PN.tail(3));
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(), "stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(2), "r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(3), "q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(4), "q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.tail(5), "q/r/stuff.it")
    `FAIL_UNLESS_STR_EQUAL(my_PN.extension(), ".it")

    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(), "q/r");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(2), "q");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(3), "");
    `FAIL_UNLESS_STR_EQUAL(my_PN.dirname(4), "");

    `FAIL_UNLESS_STR_EQUAL(my_PN.basename(), "q/r/stuff");

  `SVTEST_END

  
  `SVUNIT_TESTS_END

endmodule