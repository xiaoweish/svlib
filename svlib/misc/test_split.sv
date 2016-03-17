`include "svlib_pkg.sv"

module test_split;

  import svlib_pkg::*;
  
  int test_limits[$] = {0, -1, 2, 1};
  
  initial begin
    Regex re;
    string result[$];
    string src;
    string splitter;
    
    re = Regex::create();

    `foreach_line($fopen("../misc/split_test_data", "r"), line, linenum) begin
    
      if (linenum%2) begin
        splitter = str_strip(line, "\n");
        continue;
      end

      src = str_strip(line, "\n");
      
      re.setStrContents(src);
      re.setRE(splitter);

      foreach (test_limits[i]) begin
        $display("split(%s, %s) (%0d)", str_quote(splitter), str_quote(src), test_limits[i]);
        result = re.split(test_limits[i]);
        for (int n = 0; n < result.size(); n++) begin
          $display("  %2d: %s", n, str_quote(result[n]));
        end
      end
      $display();

    end
    
  end
  
endmodule
