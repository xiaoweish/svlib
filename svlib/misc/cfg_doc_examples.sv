`include "svlib_macros.svh"

module node_test;

  import svlib_pkg::*;
  
  class LocalCfg;
    int    choice;
    string label;
    `SVLIB_DOM_UTILS_BEGIN(LocalCfg)
     `SVLIB_DOM_FIELD_INT(choice)
     `SVLIB_DOM_FIELD_STRING(label)
    `SVLIB_DOM_UTILS_END
  endclass

  initial begin
    cfgNodeMap    cfg_DOM;   // A generic DOM object (no need for "new")
    cfgFileINI    cfg_file;
    cfgError_enum err;
    LocalCfg      cfg;
    
    cfg = new; // The user configuration object of interest
    cfg.choice = 42;
    cfg.label = "Local Configuration";

    cfg_file = cfgFileINI::create(); // file container
    cfg_DOM = cfg.toDOM("cfg");  // Copy user object to DOM representation
    err = cfg_file.openW("user_file.ini");  // Open the file for writing
    err = cfg_file.serialize(cfg_DOM);      // Write the DOM to the file
    $display("serialize, err = %s", err.name);
    err = cfg_file.close();                 // finalize the file
    $display("close, err = %s", err.name);

  end
  
endmodule
