module test_dpi_fstat;

  import "DPI-C" function string SvLib_getCErrStr(input int errnum);
  import "DPI-C" function int SvLib_saBufNext(
                            inout  chandle hnd,
                            output string  path );
  import "DPI-C" function int SvLib_getcwd(output string result);
  import "DPI-C" function int SvLib_globStart(
                            input  string pattern,
                            output chandle hnd,
                            output int     count);
  import "DPI-C" function int SvLib_mtime(input string path, output int mtime);
  
  typedef string qS[$];
  function int SvLib_getQS(input chandle hnd, output qS ss);
    int result;
    string s;
    ss.delete();
    if (hnd == null) return -1;
    forever begin
      result = SvLib_saBufNext(hnd, s);
      if (result != 0) return result;
      if (hnd == null) return 0;
      ss.push_back(s);
    end
  endfunction

  initial begin
    string s;
    int result;
    int mtime;
    chandle hnd;
    int count;
    qS paths;
    
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
      result = SvLib_getQS(hnd, paths);
      if (result) begin
        $display("SvLib_getQS failed, result=%0d", result);
      end
      else begin
        foreach (paths[i]) begin
          $display("  path[%0d]=\"%s\"", i, paths[i]);
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

