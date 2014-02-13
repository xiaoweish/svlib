`ifndef SVLIB_PKG_DEFINED
`define SVLIB_PKG_DEFINED

`include "svlib_macros.svh"
`include "svlib_private_base_pkg.svh"

package svlib_pkg;

  import svlib_private_base_pkg::*;

  `include "svlib_pkg_Error.svh"
  `include "svlib_pkg_Str.svh"
  `include "svlib_pkg_Regex.svh"
  `include "svlib_pkg_Enum.svh"
  `include "svlib_pkg_Sys.svh"
  `include "svlib_pkg_File.svh"
  `include "svlib_pkg_Cfg.svh"

endpackage

`endif
