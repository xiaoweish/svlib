module test_dpi_fstat;

  import svlib_Base_pkg::*;
  import svlib_Sys_pkg::*;

  initial begin
    string s;
    int result;
    longint ftime, fval;
    qs paths;
    longint stats[statARRAYSIZE];
    sysFileStat_s stat;
    
    result = SvLib_getcwd(s);
    if (result) begin
      $display("failed, result=%0d \"%s\"", result, s);
    end
    else begin
      $display("success, s.len=%0d", s.len);
      $display("         s=\"%s\"", s);
    end
    
    svlibSys_errorHandling(1);
    
    paths = fileGlob("../foo/*");
    if (svlibLastError()) begin
      $display("Glob call yielded %s", svlibErrorDetails());
    end
    else begin
      $display("Directory listing of ../* :");
      foreach (paths[i]) begin
        $display("  path[%0d]=\"%s\"", i, paths[i]);
      end
    end

    stat = fileStat("README");
   if (svlibLastError()) begin
      $display("Stat call yielded %s", svlibErrorDetails());
    end
    else begin
      $display("Stat call worked");
    end
   
    $display("mtime = %0d", stat.mtime);
    result = SvLib_timeFormat(stat.mtime, "%c", s);
    if (result != 0)
      $display("  Oops, timeFormat result = %0d (%s)", result, svlibErrorString(result));
    else
      $display("  That's \"%s\"", s);
      
    $display("atime = %0d",  stat.atime);
    $display("ctime = %0d",  stat.ctime);
    $display("size  = %0d",  stat.size);
    $display("type  = %s" ,  stat.mode.fType.name);
    $display("perms = %04o", stat.mode.fPermissions);
    
    svlibSys_errorHandling(1);
    
    stat = fileStat("crapola");
    stat = fileStat("crapola");
    if (svlibLastError()) begin
      $display("That call yielded an error (%s)", svlibErrorString());
    end
    else begin
      $display("That stat call worked");
    end
    
    ftime = SvLib_dayTime();
    $display("unix time now = %0d", ftime);
    result = SvLib_timeFormat(ftime, "%c", s);
    if (result != 0)
      $display("  Oops, timeFormat result = %0d (%s)", result, svlibErrorString(result));
    else
      $display("  That's \"%s\"", s);
    

    $display("Finishing");
    
  end

endmodule

