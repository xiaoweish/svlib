`include "svlib_macros.svh"

module test_forenum;

  import svlib_pkg::*;

  typedef enum {iA=7, iB, iC} IntEnum;
  typedef enum logic[1:0] {bA=2'b1z, bB=2'b01, bC=2'bz0} TwobitEnum;
  typedef EnumUtils#(TwobitEnum) TBE;
  
  initial begin
    TBE::qe allTBE;
    $display("IntEnum[i]=e:");
    `foreach_enum(IntEnum, e, i) $display("Int[%0d]=%s(%0d)", i, e.name, e);
    $display("IntEnum[q]=p:");
    `foreach_enum(IntEnum, p, q) $display("Int[%0d]=%s(%0d)", q, p.name, p);
    $display("TwobitEnum[i]=e:");
    `foreach_enum(TwobitEnum, e, i) begin
      bit [1:0] v;
      string s;
      TwobitEnum tbe;
      bit   has_name;
      bit  has_value;
      v = e;
      s = e.name;
      tbe = TBE::from_name(s);
      has_name = TBE::has_name(s);
      has_value = TBE::has_value(v);
      $display("Twobit[%0d]=%s(%0d)", i, e.name, e);
      $display("  map(%s) = %s(%d), has_value(2'b%b)=%b, has_name(%s)=%b",
                      s,  tbe.name, tbe, v, has_value, s, has_name);
    end
    allTBE = TBE::all_values();
    $display($typename(allTBE));
//    foreach (allTBE[i]) $display("allTBE[%0d] = %s", i, allTBE[i].name);
    for (int i=0; i<4; i++) $display("TBE::has_value(%0d) = %b", i, TBE::has_value(i));
    $display("TBE::has_name(foo) = %b", TBE::has_name("foo"));
    $display("TBE::has_name() = %b", TBE::has_name(""));
    
    $display();
    `foreach_enum(TwobitEnum,ee) $display("ee=%s('b%b)", ee.name, ee);
    $display("Match (not necessarily unique):");
    for (int i=0; i<5; i++) begin
      TwobitEnum match;
      match = TBE::match(i);
      $display("  Try to match %0d in TBE: value=%s('b%b)", i, match.name, match);
    end
    $display("Match requiring uniqueness:");
    for (int i=0; i<5; i++) begin
      TwobitEnum match;
      match = TBE::match(i, 1);
      $display("Unique %0d in TBE: value=%s('b%b)", i, match.name, match);
    end
    
    $display("\nNesting:");
    `foreach_enum(TwobitEnum,e) begin
      $display("  %s", e.name);
      `foreach_enum(TwobitEnum,e)
        $display("    %s", e.name);
    end
    
  end

endmodule
