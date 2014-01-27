`ifndef SVLIB_ENUM_PKG__DEFINED
`define SVLIB_ENUM_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Enum_pkg;
  
  import svlib_Base_pkg::*;

  // Class to provide utility services for an enum.
  // The type parameter MUST be overridden with an appropriate enum type.
  // Leaving it at the default 'int' will give tons of elaboration-time errors.
  // Nice polite 1800-2012-compliant tools should allow me to provide no default
  // at all on the type parameter, enforcing the requirement for an override;
  // but certain tools that shall remain nameless don't yet support that.
  //
  class EnumUtils #(type ENUM = int);

    typedef ENUM qe[$];
    typedef logic [$bits(ENUM)-1:0] BASE;

    // Public methods (implementation appears later)
    extern static function ENUM from_name  (string s);
    extern static function int  pos        (BASE   b);
    extern static function bit  has_name   (string s);
    extern static function bit  has_value  (BASE   b);
    extern static function qe   all_values ();

    // List of all values, lazy-evaluated
    protected static qe   m_all_values;
    protected static ENUM m_map[string];
    protected static int  m_pos[BASE];
    protected static bit  m_built;

    protected static function void m_build();
      ENUM e = e.first;
      for (int pos=0; pos<e.num; pos++) begin
        m_all_values.push_back(e);
        m_map[e.name] = e;
        m_pos[e] = pos;
        e = e.next;
      end
      m_built = 1;
    endfunction

    protected ENUM e;
    protected bit more;
    function new; start(); endfunction
    function void start(); e = e.first; more = 1; endfunction
    function bit  next(output ENUM re); re = e; next = more; e = e.next; more = (e != e.first); endfunction
    function bit  ready(); return more; endfunction
  endclass

  `include "svlib_Enum_impl.sv"

endpackage

`endif
