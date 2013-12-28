import svunit_pkg::*;

module __testsuite;
  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  Str_unit_test Str_ut();
  Regex_unit_test Regex_ut();


  //===================================
  // Build
  //===================================
  function void build();
    Str_ut.build();
    Regex_ut.build();
    svunit_ts = new(name);
    svunit_ts.add_testcase(Str_ut.svunit_ut);
    svunit_ts.add_testcase(Regex_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    Str_ut.run();
    Regex_ut.run();
    svunit_ts.report();
  endtask

endmodule
