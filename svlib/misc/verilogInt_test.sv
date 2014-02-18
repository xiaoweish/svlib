`include "svlib_macros.svh"

module verilogInt_test;

  import svlib_pkg::*;
  
  initial begin
  
    int   f;
    logic signed [63:0] logic_s64;
    bit   ok;
    
    f = $fopen("verilog_ints", "r");
    
    `foreach_line(f, line, n) begin
      line = str_trim(line);
      if (line.len == 0) continue;
      
      logic_s64 = 'hDEAD_BEEF;
      ok  = scanVerilogInt(line, logic_s64);
      
      if (!ok)
        $display("could not scan \"%s\"", line);
      $display("%12s 'h%h ...%b", line, logic_s64, logic_s64[7:0]);
      
    end
    
    $fclose(f);

  end

endmodule
