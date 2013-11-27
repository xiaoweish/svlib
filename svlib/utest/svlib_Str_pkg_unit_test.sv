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
  
  function automatic string displayable(string q[$]);
    string result;
    foreach (q[i]) result = {result, " \"", q[i], "\""};
    return result;
  endfunction
  
  `SVUNIT_TESTS_BEGIN
  
  `SVTEST(Str_create_check)

    Str str;
    
    test_str = "";
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    `FAIL_UNLESS_EQUAL(my_Str.len(), test_str.len)
    
    test_str = "hello world";
    my_Str = Str::create(test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), test_str)
    `FAIL_UNLESS_EQUAL(my_Str.len(), test_str.len)
    
    str = my_Str.copy();
    `FAIL_UNLESS_STR_EQUAL(str.get(), test_str)
    
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
  
  `SVTEST(Str_replace_check)
  
    my_Str.set("abc");
    my_Str.append("def");
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "abcdef")
    my_Str.replace("123", 0, 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "123abcdef")
    my_Str.replace("", -1, 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "123abcdef")
    my_Str.replace("0", -1, 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdef")
    my_Str.replace("", -1, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdef")
    my_Str.replace("z", -1, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0123abcdefz")
    my_Str.replace("EXTRA", 1, 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefz")
    my_Str.replace("EXTRA", 1, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefEXTRAz")
    my_Str.replace("-", 100, 0);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "0EXTRA123abcdefEXTRAz-")
    my_Str.replace("=", 100, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(my_Str.get(), "=0EXTRA123abcdefEXTRAz-")
    
  `SVTEST_END
  
  `SVTEST(Str_replace_global_check)
  
    string S;
    int D, C, G, P;
    
    /*
    Obstack#(Str)::stats(D, C, G, P);
    //`INFO($sformatf("depth=%0d, constructed=%0d, get_calls=%0d, put_calls=%0d", D, C, G, P));
    `FAIL_UNLESS(G>=P)
    `FAIL_UNLESS(D+G-P==C)
    */
    
    S = "abcdef";
    S = str_replace(S, "123", 0);
    `FAIL_UNLESS_STR_EQUAL(S, "123abcdef")
    S = str_replace(S, "", -1);
    `FAIL_UNLESS_STR_EQUAL(S, "123abcdef")
    S = str_replace(S, "0", -1);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdef")
    S = str_replace(S, "", -1, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdef")
    S = str_replace(S, "z", 0, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0123abcdefz")
    S = str_replace(S, "EXTRA", 1, 0, Str::START);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefz")
    S = str_replace(S, "EXTRA", 1, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefEXTRAz")
    S = str_replace(S, "-", 100, 0, Str::START);
    `FAIL_UNLESS_STR_EQUAL(S, "0EXTRA123abcdefEXTRAz-")
    S = str_replace(S, "=", 100, 0, Str::END);
    `FAIL_UNLESS_STR_EQUAL(S, "=0EXTRA123abcdefEXTRAz-")
    
    /*
    Obstack#(Str)::stats(D, C, G, P);
    //`INFO($sformatf("depth=%0d, constructed=%0d, get_calls=%0d, put_calls=%0d", D, C, G, P));
    `FAIL_UNLESS(G>=P)
    `FAIL_UNLESS(C>0)
    `FAIL_UNLESS(D+G-P==C)
    */
    
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

  `SVTEST(Str_range_check)
  
    test_str = "0123456789";

    my_Str.set(test_str);
    
    // Calls that should return the whole string
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0,10), test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0,-10, Str::END), test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-1,11), test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-1,12), test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-1,-11, Str::END), test_str);
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-1,-12, Str::END), test_str);
    
    // Calls that should return an empty string
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0,-10), "");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0,10, Str::END), "");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5,0), "");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5,0, Str::END), "");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(28,5), "");
    
    // Slices including the left end
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0, 5, Str::START), "01234");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-2, 7, Str::START), "01234");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0, 1, Str::START), "0");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, -5, Str::END), "01234");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, -6, Str::END), "01234");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(10, 1, Str::END), "0");
    
    // Slices including the right end
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0, -5, Str::END), "56789");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(-2, -7, Str::END), "56789");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(0, -1, Str::END), "9");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, 5, Str::START), "56789");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, 6, Str::START), "56789");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(10, -1, Str::START), "9");
    
    // Slices from the middle
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(1, 5, Str::START), "12345");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, 2, Str::END), "56");
    `FAIL_UNLESS_STR_EQUAL(my_Str.range(5, -2, Str::END), "34");

  `SVTEST_END

  `SVTEST(Str_locate_check)

  int located;
  string sought;
  
  my_Str.set("012345678901234567890");
  // Seek something that's not in the string
  sought = "A";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought), -1)
  sought = "1235";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought), -1)
  
  // Find occurrences of a single character
  sought = "0";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought), 0);
  `FAIL_UNLESS_EQUAL(my_Str.last(sought), 20);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 1), 10);
  `FAIL_UNLESS_EQUAL(my_Str.last(sought, 1), 10);
  
  // Find occurrences of a longer string
  sought = "0123";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought),      0);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought),     10);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 1),  10);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought, 1),  10);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 10), 10);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 11), -1);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought, 11),  0);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought, 18), -1);
  //
  sought = "890";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought),      8);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought),     18);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 1),   8);
  `FAIL_UNLESS_EQUAL(my_Str.first(sought, 9),  18);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought, 1),   8);

  // Matching but too long
  sought = "0123456789012345678901";
  `FAIL_UNLESS_EQUAL(my_Str.first(sought),     -1);
  `FAIL_UNLESS_EQUAL(my_Str.last (sought),     -1);

  `SVTEST_END

  `SVTEST(Str_split_check)
  
  string test_str = "aabcdefff";
  string expected[$] = {};
  string actual[$];
  my_Str.set(test_str);
  
  actual = my_Str.split("");
  expected.delete();
  for (int i=0; i<test_str.len(); i++)
    expected.push_back(test_str.substr(i,i));
  `FAIL_UNLESS_EQUAL(expected, actual);

  actual = my_Str.split("b");
  expected = {"aa", "cdefff"};
  `FAIL_UNLESS_EQUAL(expected, actual);

  actual = my_Str.split("bf");
  expected = {"aa", "cde", "", "", ""};
  `FAIL_UNLESS_EQUAL(expected, actual);

  actual = my_Str.split("abc");
  expected = {"", "", "", "", "defff"};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("pqr");
  expected = {"aabcdefff"};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("p");
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  my_Str.set("a");
  
  actual = my_Str.split("cde");
  expected = {"a"};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("");
  expected = {"a"};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("a");
  expected = {"", ""};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  my_Str.set("");
  
  actual = my_Str.split("");
  expected = {};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("a");
  expected = {""};
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  actual = my_Str.split("ab");
  `FAIL_UNLESS_EQUAL(expected, actual);
  
  `SVTEST_END

  `SVTEST(Str_join_check)

  my_Str.set("ABC");
  `FAIL_UNLESS_STR_EQUAL("", my_Str.sjoin({}) )
  `FAIL_UNLESS_STR_EQUAL("Single", my_Str.sjoin({"Single"}))
  `FAIL_UNLESS_STR_EQUAL("oneABCtwo", my_Str.sjoin({"one", "two"}))
  `FAIL_UNLESS_STR_EQUAL("ABCtwo", my_Str.sjoin({"", "two"}))
  `FAIL_UNLESS_STR_EQUAL("oneABCtwoABCthree", my_Str.sjoin({"one", "two", "three"}))
  
  my_Str.set("");
  `FAIL_UNLESS_STR_EQUAL("", my_Str.sjoin({}))
  `FAIL_UNLESS_STR_EQUAL("Single", my_Str.sjoin({"Single"}))
  `FAIL_UNLESS_STR_EQUAL("onetwo", my_Str.sjoin({"one", "two"}))
  `FAIL_UNLESS_STR_EQUAL("two", my_Str.sjoin({"", "two"}))
  `FAIL_UNLESS_STR_EQUAL("onetwothree", my_Str.sjoin({"one", "two", "three"}))
  
  `SVTEST_END

  `SVTEST(RE_check)
  
  Regex re;
  int result;
  
  re = Regex::create("a(b)c");
  my_Str.set("012abc678");
  result = re.test(my_Str, 0);
  $display("\n\"%s\" =~ \"%s\"", my_Str.get(), re.getRE());
  for (int i=0; i<re.getMatchCount(); i++) begin
    int L, R;
    string match;
    result = re.getMatchPosition(i, L, R);
    result = re.getMatchString(i, match);
    $display("match[%0d] = [%0d:%0d] \"%s\"", i, L, R, match);
  end
  result = re.test(my_Str, 1);
  $display("\n\"%s\" =~ \"%s\"", my_Str.get(), re.getRE());
  for (int i=0; i<re.getMatchCount(); i++) begin
    int L, R;
    string match;
    result = re.getMatchPosition(i, L, R);
    result = re.getMatchString(i, match);
    $display("match[%0d] = [%0d:%0d] \"%s\"", i, L, R, match);
  end
  my_Str.set("012345678");
  result = re.test(my_Str, 0);
  $display("\n\"%s\" =~ \"%s\"", my_Str.get(), re.getRE());
  for (int i=0; i<re.getMatchCount(); i++) begin
    int L, R;
    string match;
    result = re.getMatchPosition(i, L, R);
    result = re.getMatchString(i, match);
    $display("match[%0d] = [%0d:%0d] \"%s\"", i, L, R, match);
  end
  
  re.setRE("a(bc");
  `FAIL_UNLESS(re.getError()==-1)
  result = re.test(my_Str, 0);
  `FAIL_UNLESS(result!=0)
    
    
  re = regexMatch(.haystack("yes, we have no bananas"), .needle("A"), .options(0));
  `FAIL_UNLESS(re==null)
  re = regexMatch(.haystack("yes, we have no bananas"), .needle("A"), .options(Regex::NOCASE));
  `FAIL_UNLESS(re!=null)
  begin
    int L, R;
    string match;
    result = re.getMatchPosition(0, L, R);
    result = re.getMatchString(0, match);
    `FAIL_UNLESS_EQUAL(L,9)
    `FAIL_UNLESS_EQUAL(R,9)
    `FAIL_UNLESS_STR_EQUAL(match, "a")
  end
  `FAIL_UNLESS(re.retest(.startPos(10))==0)
  begin
    int L, R;
    string match;
    result = re.getMatchPosition(0, L, R);
    `FAIL_UNLESS_EQUAL(L,17)
    `FAIL_UNLESS_EQUAL(R,17)
  end
  
  re.setRE("(na)+");
  re.setOpts(0);
  result = re.test(.s(Str::create("yes, we have no bananas")),.startPos(17));
  `FAIL_UNLESS(result==0)
  begin
    int L, R;
    string match;
    result = re.getMatchPosition(0, L, R);
    result = re.getMatchString(0, match);
    `FAIL_UNLESS_EQUAL(L,18)
    `FAIL_UNLESS_EQUAL(R,21)
    `FAIL_UNLESS_STR_EQUAL(match, "nana")
    result = re.getMatchPosition(1, L, R);
    result = re.getMatchString(1, match);
    `FAIL_UNLESS_EQUAL(L,20)
    `FAIL_UNLESS_EQUAL(R,21)
    `FAIL_UNLESS_STR_EQUAL(match, "na")
  end
  
  re = regexMatch("yes, we have no bananas", "z");
  `FAIL_UNLESS(re == null)
  
  re = regexMatch("yes, we have no bananas", "x(z");
  `FAIL_UNLESS(re == null)
  
  `SVTEST_END
  
  `SVUNIT_TESTS_END

endmodule
