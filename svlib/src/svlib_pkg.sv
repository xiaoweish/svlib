`ifndef SVLIB_PKG_DEFINED
`define SVLIB_PKG_DEFINED

`include "svlib_macros.svh"
`include "svlib_private_base_pkg.sv"

package svlib_pkg;

  import svlib_private_base_pkg::*;

  `include "svlib_pkg_Str.sv"
  `include "svlib_pkg_Regex.sv"
  `include "svlib_pkg_Enum.sv"
  `include "svlib_pkg_File.sv"
  `include "svlib_pkg_Sys.sv"
  `include "svlib_pkg_Cfg.sv"

endpackage

`endif
