module test_dpi_fstat;

  import "DPI-C" function string SvLib_getCErrStr(input int errnum);
  import "DPI-C" function int SvLib_getcwd(output string result);
  import "DPI-C" function int SvLib_globStart(
                            input  string pattern,
                            output chandle hnd,
                            output int     count);
  import "DPI-C" function int SvLib_globNext(
                            inout  chandle hnd,
                            output string  path );
  import "DPI-C" function int SvLib_mtime(input string path, output int mtime);
  
  initial begin
    string s;
    int result;
    int mtime;
    chandle hnd;
    int count;
    
    result = SvLib_getcwd(s);

    if (result) begin
      $display("failed, result=%0d \"%s\"", result, s);
    end
    else begin
      $display("success, s.len=%0d", s.len);
      $display("         s=\"%s\"", s);
    end
    
    result = SvLib_globStart("../*", hnd, count);
    if (result) begin
      $display("globStart failed, result=%0d", result);
    end
    else begin
      $display("globStart: number=%0d", count);
      forever begin
        result = SvLib_globNext(hnd, s);
        if (result) begin
          $display("globNext failed, result=%0d", result);
          break;
        end
        else begin
          $display("globNext(hnd, \"%s\")", s);
          if (hnd == null) break;
        end
      end
    end

    result = SvLib_mtime("irun.log", mtime);

    if (result) begin
      $display("mtime failed, result=%0d", result);
    end
    else begin
      $display("mtime success, mtime=%0d", mtime);
    end
    
    

    $display("Finishing");
    
  end

endmodule

