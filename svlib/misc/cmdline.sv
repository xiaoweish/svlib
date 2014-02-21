module cmdline;

  import svlib_pkg::*;
  
  initial begin
    string cmdOpts[$];
    $display("Tool    : \"%s\"", Simulator::getToolName());
    $display("Version : \"%s\"", Simulator::getToolVersion());
    $display("Cmd line:");
    cmdOpts = Simulator::getCmdLine();
    foreach (cmdOpts[i]) begin
      $display("  [%2d] : \"%s\"", i, cmdOpts[i]);
    end
  end
  
endmodule
