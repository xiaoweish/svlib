`ifndef SVLIB_SYS_PKG__DEFINED
`define SVLIB_SYS_PKG__DEFINED

`include "svlib_macros.sv"


package svlib_Sys_pkg;

  import svlib_Base_pkg::*;
  
  `include "svlib_shared_c_sv.h"

  import "DPI-C" function string  SvLib_getCErrStr (input int errnum);
  import "DPI-C" function int     SvLib_getcwd     (output string result);
  import "DPI-C" function int     SvLib_globStart  (input  string pattern,
                                                    output chandle hnd,
                                                    output int     count);
  import "DPI-C" function int     SvLib_stat       (input  string  path,
                                                    input  int     what,
                                                    output longint value);
  import "DPI-C" function longint SvLib_dayTime    ();
  import "DPI-C" function int     SvLib_timeFormat (input  longint tm,
                                                    input  string  format,
                                                    output string formatted);

endpackage

`endif
