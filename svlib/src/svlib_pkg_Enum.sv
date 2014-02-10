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
  extern static function ENUM match      (BASE   b, bit requireUnique = 0);

  // List of all values, lazy-evaluated
  protected static qe   m_all_values;
  protected static ENUM m_map[string];
  protected static int  m_pos[BASE];
  protected static bit  m_built;
  // The lazy-evaluator
  extern protected static function void m_build();

endclass

`include "svlib_Enum_impl.sv"
