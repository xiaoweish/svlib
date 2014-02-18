`include "svlib_macros.svh"

module ini_test;

  import svlib_pkg::*;
  
  initial begin
  
    int     f;
    cfgNode root;
    
    cfgFileINI fi;
    cfgError_enum err;

    fi = cfgFileINI::create("INI file my.ini");
    err = fi.openR("test.ini");
    $display("\nopenR: %s", err.name);
    root = fi.deserialize();
    void'(fi.close());
    
    $display();
    $display(root.sformat(1));
    $display();

    err = fi.openW("test_copy.ini");
    $display("\nopenW: %s", err.name);

    err = fi.serialize(root);
    $display("serialize: %s", err.name);

    err = fi.close();
    $display("close: %s\n", err.name);

  end

endmodule
