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
      bit   hasName;
      bit  hasValue;
      v = e;
      s = e.name;
      tbe = TBE::fromName(s);
      hasName = TBE::hasName(s);
      hasValue = TBE::hasValue(v);
      $display("Twobit[%0d]=%s(%0d)", i, e.name, e);
      $display("  map(%s) = %s(%d), hasValue(2'b%b)=%b, hasName(%s)=%b",
                      s,  tbe.name, tbe, v, hasValue, s, hasName);
    end
    allTBE = TBE::allValues();
//    $display($typename(allTBE));
    foreach (allTBE[i]) $display("allTBE[%0d] = %s", i, allTBE[i].name);
    foreach (allTBE[i]) $display("allTBE[%0d] pos = %0d", i, TBE::pos(allTBE[i]));
    for (int i=0; i<4; i++) $display("TBE::hasValue(%0d) = %b", i, TBE::hasValue(i));
    $display("TBE::hasName(foo) = %b", TBE::hasName("foo"));
    $display("TBE::hasName() = %b", TBE::hasName(""));
    
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
