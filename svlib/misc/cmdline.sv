module cmdline;

  import svlib_pkg::*;
  
  initial begin
    string define_plusarg;
    string cmdOpts[$];
    $value$plusargs("define+%s", define_plusarg);
    $display("Plusarg +define+ was \"%s\"", define_plusarg);
    $value$plusargs("bogus+%s", define_plusarg);
    $display("Plusarg +bogus+ was \"%s\"", define_plusarg);
    $display("Tool    : \"%s\"", Simulator::getToolName());
    $display("Version : \"%s\"", Simulator::getToolVersion());
    $display("Cmd line:");
    cmdOpts = Simulator::getCmdLine();
    foreach (cmdOpts[i]) begin
      $display("  [%2d] : \"%s\"", i, cmdOpts[i]);
    end
  end
  
endmodule
