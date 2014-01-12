`include "svunit_defines.svh"

`include "svlib_Base_pkg.sv"
`include "svlib_Str_pkg.sv"

module Regex_unit_test;

  import svunit_pkg::*;
  import svlib_Base_pkg::qs;
  import svlib_Str_pkg::*;

  string name = "Regex_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  Regex re;
  Str   str;

  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
    str = Str::create("");
    re  = Regex::create("");
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
  
  function automatic string displayable(string q[$]);
    string result;
    foreach (q[i]) result = {result, " \"", q[i], "\""};
    return result;
  endfunction
  
  `SVUNIT_TESTS_BEGIN
  
  `SVTEST(RE_check)
  
  int result;
  
  re.setRE("a(b)c");
  str.set("012abc678");
  result = re.test(str, 0);
  `FAIL_UNLESS(result)
  `FAIL_UNLESS_EQUAL(re.getMatchCount(),2)
  `FAIL_UNLESS_EQUAL(re.getMatchStart(0),3)
  `FAIL_UNLESS_EQUAL(re.getMatchLength(0),3)
  `FAIL_UNLESS_EQUAL(re.getMatchStart(1),4)
  `FAIL_UNLESS_EQUAL(re.getMatchLength(1),1)
  `FAIL_UNLESS_EQUAL(re.getMatchStart(2),-1)

  str.set("012345678");
  result = re.test(str, 0);
  `FAIL_IF(result)
  
  re.setRE("a(bc");
  `FAIL_UNLESS(re.getError()!=0)
  result = re.test(str, 0);
  `FAIL_UNLESS(result==0)

  re = regexMatch(.haystack("yes, we have no bananas"), .needle("A"), .options(0));
  `FAIL_UNLESS(re==null)
  re = regexMatch(.haystack("yes, we have no bananas"), .needle("A"), .options(Regex::NOCASE));
  `FAIL_UNLESS(re!=null)
  begin
    int L, len;
    string match;
    L = re.getMatchStart(0);
    len = re.getMatchLength(0);
    match = re.getMatchString(0);
    `FAIL_UNLESS_EQUAL(L,9)
    `FAIL_UNLESS_EQUAL(len,1)
    `FAIL_UNLESS_STR_EQUAL(match, "a")
  end
  `FAIL_UNLESS(re.retest(.startPos(10)))
  begin
    int L, len;
    string match;
    L = re.getMatchStart(0);
    len = re.getMatchLength(0);
    `FAIL_UNLESS_EQUAL(L,17)
    `FAIL_UNLESS_EQUAL(len,1)
  end
  
  re.setRE("(na)+");
  re.setOpts(0);
  result = re.test(.s(Str::create("yes, we have no bananas")),.startPos(17));
  `FAIL_UNLESS(result)
  begin
    int L, len;
    string match;
    L = re.getMatchStart(0);
    len = re.getMatchLength(0);
    match = re.getMatchString(0);
    `FAIL_UNLESS_EQUAL(L,18)
    `FAIL_UNLESS_EQUAL(len,4)
    `FAIL_UNLESS_STR_EQUAL(match, "nana")
    L = re.getMatchStart(1);
    len = re.getMatchLength(1);
    match = re.getMatchString(1);
    `FAIL_UNLESS_EQUAL(L,20)
    `FAIL_UNLESS_EQUAL(len,2)
    `FAIL_UNLESS_STR_EQUAL(match, "na")
  end
  
  `SVTEST_END
  
  `SVTEST(regexMatch_fail_check)
  
  re = regexMatch("yes, we have no bananas", "z");
  `FAIL_UNLESS(re == null)
  
  re = regexMatch("yes, we have no bananas", "x(z");
  `FAIL_UNLESS(re == null)
  
  `SVTEST_END
  
  `SVTEST(RE_subst_check)
  int count;
  str.set("yes, we have no bananas");
  re = Regex::create("we");
  count = re.subst(str, "you");
  `FAIL_UNLESS_EQUAL(count,1)
  `FAIL_UNLESS_STR_EQUAL(str.get(), "yes, you have no bananas")
  
  re.setRE("a(.)");
  count = re.substAll(str, "a$1$$$1");
  `FAIL_UNLESS_EQUAL(count,4)
  `FAIL_UNLESS_STR_EQUAL(str.get(), "yes, you hav$ve no ban$nan$nas$s")
  
  re.setRE("(.)\\$\\1");
  count = re.substAll(str, "$1");
  `FAIL_UNLESS_EQUAL(count,4)
  `FAIL_UNLESS_STR_EQUAL(str.get(), "yes, you have no bananas")
  
  `SVTEST_END
  
  `SVUNIT_TESTS_END

endmodule