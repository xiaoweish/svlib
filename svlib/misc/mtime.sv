module mtime;

  import svlib_pkg::*;
  
  function void fileStats(string path);
    $display("file \"%s\":", path);
    $display(sys_formattedTime(file_mTime(path), "  mtime = %c"));
    $display(sys_formattedTime(file_mTime(path), "%Q"));
  endfunction
  
  initial begin
    fileStats("mtime.f");
    fileStats("..");
  end
  
endmodule
