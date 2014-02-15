module test_dpi_fstat;

  import svlib_pkg::*;

  initial begin
    string s;
    int result;
    longint ftime, fval;
    string paths[$];
    sys_fileStat_s stat;
    
    s = sys_getcwd();
    result = error_getLast();
    if (result) begin
      $display("getcwd failed, result=%0d \"%s\"", result, s);
    end
    else begin
      $display("getcwd success, \"%s\"", s);
    end
    
    error_userHandling(0);
    
    $display("Illegal glob attempt");
    paths = sys_fileGlob("../foo/*");
    if (error_getLast()) begin
      $display("Glob call yielded %s", error_details());
    end
    else*/ begin
      $display("Directory listing of ../foo/* :");
      foreach (paths[i]) begin
        $display("  path[%0d]=\"%s\"", i, paths[i]);
      end
    end
    
    $display("Empty glob attempt");
    paths = sys_fileGlob("../foo");
    if (error_getLast()) begin
      $display("sys_fileGlob call yielded %s", error_details());
    end
    else begin
      $display("Directory listing of ../foo :");
      foreach (paths[i]) begin
        $display("  path[%0d]=\"%s\"", i, paths[i]);
      end
    end
    
    $display("Non-empty glob attempt");
    paths = sys_fileGlob("../*");
    if (error_getLast()) begin
      $display("sys_fileGlob call yielded %s", error_details());
    end
    else begin
      $display("Directory listing of ../* :");
      foreach (paths[i]) begin
        $display("  path[%0d]=\"%s\"", i, paths[i]);
      end
    end
    

    error_userHandling(1);
    
    stat = sys_fileStat("README");
    if (error_getLast()) begin
      $display("fileStat(\"README\") yielded %s", error_details());
    end
    else begin
      $display("fileStat(\"README\") worked");
    end
   
    $display("mtime = %0d", stat.mtime);
    s = sys_formatTime(stat.mtime, "%c");
    result = error_getLast();
    if (result != 0)
      $display("  Oops, sys_formatTime result = %0d (%s)", result, error_text(result));
    else
      $display("  That's \"%s\"", s);
      
    $display("atime = %0d",  stat.atime);
    $display("ctime = %0d",  stat.ctime);
    $display("size  = %0d",  stat.size);
    $display("type  = %s" ,  stat.mode.fType.name);
    $display("perms = 0%04o", stat.mode.fPermissions);
    
    fork
      stat = sys_fileStat("nonexistentFile");
    join_none
    fork begin
      stat = sys_fileStat("nonexistentFile");
      if (error_getLast()) begin
        $display("fileStat(\"nonexistentFile\") yielded an error (%s)", error_text());
      end
      else begin
        $display("fileStat(\"nonexistentFile\") worked");
      end
    end join_none
    wait fork;
    
    ftime = sys_dayTime();
    $display("unix time now = %0d", ftime);
    s = sys_formatTime(ftime, "%c");
    if (error_getLast())
      $display("  Oops, sys_formatTime error = %0d (%s)", result, error_text());
    else
      $display("  That's \"%s\"", s);
    

    $display("Finishing");
    $display(str_sjoin(errorManager.report(), "\n"));
    
  end

endmodule

