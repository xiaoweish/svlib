`ifndef STDLIB_PKG__DEFINED
`define STDLIB_PKG__DEFINED

`include "stdlib_macros.sv"
/*
package svlib_pkg;

  typedef string qs[$];
  
  virtual class svlib_base;
  endclass
  
  // Str: various string manipulations.
  // Most functions come in two flavors:
  // - a package version named str_XXX that takes a string value,
  //   does some work on it and returns a result; and
  // - an object version named .XXX that operates on a stored
  //   Str object, possibly returning a result and possibly
  //   modifying the stored object.
  //
  class Str extends svlib_base;
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    extern static function Str    create(string s = "");
    extern        function string get();
    extern        function void   set(string s);
    
    // Find the first occurrence of substr in s, starting from the "start"
    // position. If a match is found, return the index of the first character
    // of the match.  If no match is found, return -1.
    extern static function int str_locate(string s, string substr, int start=0);
    extern        function int     locate(          string substr, int start=0);
    
    // Split a string on every occurrence of a given character
    extern static function qs  str_split(string s, string splitset);
    extern        function qs      split(          string splitset);
    
    // Join a string by adding another string between each pair of elements
    extern static function string str_join(qs ss, string joinstr);
    
    // Replace the range [l:r] with some other string, not necessarily same length
    extern static function string str_replace(string s, int l, int r, string rs);
    extern        function string     replace(          int l, int r, string rs);
    
    // Return the n characters from position p. If p<0, count back from [length].
    extern static function string str_range(string s, int p, int n);
    extern static function            range(          int p, int n);
    
    // Tokenize a string on whitespace boundaries
    extern static function qs str_tokens(string s);
    extern        function qs     tokens(        );
    
    // Trim a string (remove leading and/or trailing whitespace)
    extern static function string str_trim     (string s);
    extern static function string str_trimLeft (string s);
    extern static function string str_trimRight(string s);
    
    // Filename manipulations
    extern static function string str_fileJoin (qs components);
    extern static function qs     str_fileSplit(string path);
    extern static function string str_fileDir  (string path);
    extern static function string str_fileTail (string path);
    extern static function string str_fileExtn (string path);
    extern static function string str_fileBase (string path);
    
  endclass
  
endpackage
*/
package enum_utils_pkg;

   // Class to provide utility services for an enum.
   // Currently there's only one public method here, but it may grow...
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
      extern static function bit  has_name   (string s);
      extern static function bit  has_value  (BASE   b);
      extern static function qe   all_values ();

      // List of all values, lazy-evaluated
      protected static qe   m_all_values;
      protected static ENUM m_map[string];
      protected static bit  m_built;
      
      protected static function void m_build();
        ENUM e = e.first;
        repeat (e.num) begin
          m_all_values.push_back(e);
          m_map[e.name] = e;
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

   function EnumUtils::qe EnumUtils::all_values();
     if (!m_built) m_build();
     return m_all_values;
   endfunction

   function bit EnumUtils::has_name(string s);
     if (!m_built) m_build();
     return m_map.exists(s);
   endfunction

   function bit EnumUtils::has_value(EnumUtils::BASE b);
     if (!m_built) m_build();
     return ENUM'(b) inside {m_all_values};
   endfunction

   function EnumUtils::ENUM EnumUtils::from_name(string s);
     ENUM result; // default init value
     if (!m_built) m_build();
     if (has_name(s))
       result = m_map[s];
     return result;
   endfunction

endpackage
/*
package SvLib_DOM_pkg;

  class DomBase;
  endclass
  
  class DomScalar #(type T = string) extends DomBase;
    function int get(output T rep);
    endfunction
    function void set(T rep);
    endfunction
  endclass

endpackage
*/

`endif
