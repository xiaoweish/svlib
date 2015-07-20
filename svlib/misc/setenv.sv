`include "svlib_pkg.sv"

module test_env;

  import svlib_pkg::*;
  
  import "DPI-C" function int setenv(string name,  string value, int overwrite);
  
  function void showenv(string name);
    string s;
    int ok;
    ok = sys_hasEnv(name);
    s = sys_getEnv(name);
    $display("\"%s\" existence: %0d, value \"%s\"", name, ok, s);
  endfunction

  initial begin
  
    int ok;
    
    showenv("TEST_VAR1");
    showenv("HOME");
    
    ok = setenv("TEST_VAR1", "First value", 1);
    $display("Set First value: %0d", ok);
    showenv("TEST_VAR1");

    ok = setenv("TEST_VAR1", "Second", 1);
    $display("Set Second: %0d", ok);
    showenv("TEST_VAR1");
    
    $display("$system(\"./showmyenv\")");
    $system("./showmyenv");
    $display("======================");

  end

endmodule
