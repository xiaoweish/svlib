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

  string test_str;

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);

    my_Str = Str::create(/* New arguments if needed */);
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

    test_str = "";
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    `FAIL_UNLESS_EQUAL(my_Str.len(), test_str.len)
    
    test_str = "hello world";
    my_Str = Str::create(test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    `FAIL_UNLESS_EQUAL(my_Str.len(), test_str.len)
    
  `SVTEST_END
  
  `SVTEST(Str_trim_check)
    
    test_str = "    bye bye  ";
    
    my_Str.set(test_str);
    my_Str.trim(Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "bye bye")
    my_Str.trim(Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "bye bye")
    
    my_Str.set(test_str);
    my_Str.trim(Str::NONE);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    
    my_Str.set(test_str);
    my_Str.trim(Str::LEFT);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "bye bye  ")
    
    my_Str.set(test_str);
    my_Str.trim(Str::RIGHT);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "    bye bye")
    
    my_Str.set("");
    my_Str.trim(Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "")
    
    my_Str.set("a   b");
    my_Str.trim(Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "a   b")
    
  `SVTEST_END
  
  `SVTEST(Str_insert_check)
  
    my_Str.set("abc");
    my_Str.append("def");
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "abcdef")
    my_Str.insert("123", 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "123abcdef")
    my_Str.insert("", -1);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "123abcdef")
    my_Str.insert("0", -1);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdef")
    my_Str.insert("", -1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdef")
    my_Str.insert("z", -1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdefz")
    my_Str.insert("EXTRA", 1, Str::START);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefz")
    my_Str.insert("EXTRA", 1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefEXTRAz")
    my_Str.insert("-", 100, Str::START);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefEXTRAz-")
    my_Str.insert("=", 100, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "=0EXTRA123abcdefEXTRAz-")
    
  `SVTEST_END
  
  `SVTEST(Str_insert_global_check)
  
    string S;
    int D, C, G, P;
    
    Obstack#(Str)::stats(D, C, G, P);
    `INFO($sformatf("depth=%0d, constructed=%0d, get_calls=%0d, put_calls=%0d", D, C, G, P));
//     `FAIL_UNLESS(D==0)
//     `FAIL_UNLESS(C==0)
//     `FAIL_UNLESS(G==0)
//     `FAIL_UNLESS(P==0)
    
    S = "abcdef";
    S = str_insert(S, "123", 0);
    `FAIL_UNLESS_STR_EQUAL(S, "123abcdef")
    S = str_insert(S, "", -1);
    `FAIL_UNLESS_STR_EQUAL(S, "123abcdef")
    S = str_insert(S, "0", -1);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdef")
    S = str_insert(S, "", -1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdef")
    S = str_insert(S, "z", -1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdefz")
    S = str_insert(S, "EXTRA", 1, Str::START);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefz")
    S = str_insert(S, "EXTRA", 1, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefEXTRAz")
    S = str_insert(S, "-", 100, Str::START);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefEXTRAz-")
    S = str_insert(S, "=", 100, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "=0EXTRA123abcdefEXTRAz-")
    
    Obstack#(Str)::stats(D, C, G, P);
    `INFO($sformatf("depth=%0d, constructed=%0d, get_calls=%0d, put_calls=%0d", D, C, G, P));
//     `FAIL_UNLESS(D==1)
//     `FAIL_UNLESS(C==1)
    
  `SVTEST_END
  
  `SVTEST(Str_just_check)
  
    test_str = "test";
    my_Str.set(test_str);
    
    my_Str.just(6,Str::NONE);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    `FAIL_UNLESS_EQUAL(my_Str.len(), test_str.len)
    
    my_Str.just(6,Str::RIGHT);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "  test")
    `FAIL_UNLESS_EQUAL(my_Str.len(), 6)
    
    my_Str.just(10,Str::LEFT);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "  test    ")
    `FAIL_UNLESS_EQUAL(my_Str.len(), 10)

    my_Str.just(5,Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "  test    ")
    `FAIL_UNLESS_EQUAL(my_Str.len(), 10)

    my_Str.trim();
    my_Str.just(12,Str::BOTH);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "    test    ")
    `FAIL_UNLESS_EQUAL(my_Str.len(), 12)

  `SVTEST_END



  `SVUNIT_TESTS_END

endmodule
