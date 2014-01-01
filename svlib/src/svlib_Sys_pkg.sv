`ifndef SVLIB_SYS_PKG__DEFINED
`define SVLIB_SYS_PKG__DEFINED

`include "svlib_macros.sv"


package svlib_Sys_pkg;

  import svlib_Base_pkg::*;
  
  `include "svlib_shared_c_sv.h"

  import "DPI-C" function int     SvLib_getcwd     (output string result);
  import "DPI-C" function int     SvLib_globStart  (input  string pattern,
                                                    output chandle hnd,
                                                    output int     count);
  import "DPI-C" function int     SvLib_fileStat   (input  string  path,
                                                    input  int     asLink,
                                                    output longint stats[statARRAYSIZE]);
  import "DPI-C" function longint SvLib_dayTime    ();
  import "DPI-C" function int     SvLib_timeFormat (input  longint tm,
                                                    input  string  format,
                                                    output string formatted);
  
  typedef struct packed {
    bit r;
    bit w;
    bit x;
  } sysFileRWX_s;
  
  typedef struct packed {
    bit          setUID;
    bit          setGID;
    bit          sticky;
    sysFileRWX_s owner;
    sysFileRWX_s group;
    sysFileRWX_s others;
  } sysFilePermissions_s;
  
  typedef enum bit [3:0] {
    fTypeFifo    = 4'h1,
    fTypeCharDev = 4'h2,
    fTypeDir     = 4'h4,
    fTypeBlkDev  = 4'h6,
    fTypeFile    = 4'h8,
    fTypeSymLink = 4'hA,
    fTypeSocket  = 4'hC
  } sysFileType_e;
  
  typedef struct packed {
    sysFileType_e        fType;
    sysFilePermissions_s fPermissions;
  } sysFileMode_s;
  
  typedef struct {
    longint       mtime;
    longint       atime;
    longint       ctime;
    longint       size;
    sysFileMode_s mode;
  } sysFileStat_s;
  
  function automatic sysFileStat_s fileStat(string path, bit asLink=0);
    longint stats[statARRAYSIZE];
    int err;
    err = SvLib_fileStat(path, asLink, stats);
    if (errorManager.check(err)) begin
      fileStat_check_syscall_ok:
        assert (!err) else 
          $error("Failed to stat \"%s\": %s", 
                                  path, svlibErrorDetails()
          );
    end
    if (!err) begin
      fileStat.mtime = stats[statMTIME];
      fileStat.atime = stats[statATIME];
      fileStat.ctime = stats[statCTIME];
      fileStat.size  = stats[statSIZE ];
      fileStat.mode  = stats[statMODE ];
    end
  endfunction
  
  function automatic qs fileGlob(string wildPath);
    qs      paths;
    chandle hnd;
    int     count;
    int     err;
    
    err = SvLib_globStart(wildPath, hnd, count);
    if (errorManager.check(err)) begin
      fileGlob_check_globStart_ok:
        assert (!err) else
          $error("Failed to glob \"%s\": %s", wildPath, svlibErrorDetails());
    end
    
    if (!err) begin
      err = SvLib_getQS(hnd, paths);
      if (errorManager.check(err)) begin
        fileGlob_check_getQS_ok:
          assert (!err) else
           $error("Failed to get glob strings: %s", svlibErrorDetails());
      end
    end
    
    return paths;
  endfunction

endpackage

`endif
