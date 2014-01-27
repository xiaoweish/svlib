`include "stdlib_pkg.sv"

module test_forenum;

  import enum_utils_pkg::*;

  typedef enum {iA=7, iB, iC} IntEnum;
  typedef enum bit[1:0] {bA=2'b10, bB=2'b01} TwobitEnum;
  typedef EnumUtils#(TwobitEnum) TBE;
  
  initial begin
    TBE::qe allTBE;
    $display("IntEnum, e, i:");
    `forenum(IntEnum, e, i) $display("Int[%0d]=%s(%0d)", i, e.name, e);
    $display("IntEnum, p, q:");
    `forenum(IntEnum, p, q) $display("Int[%0d]=%s(%0d)", q, p.name, p);
    $display("TwobitEnum, e, i:");
    `forenum(TwobitEnum, e, i) begin
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
    
    `forenum(TwobitEnum,ee) $display("ee=%s(%0d)", ee.name, ee);
    
    //$display("\nTrying iterator approach:");
    //for (TBE ei = new, TwobitEnum tbe=tbe.last; ei.next(tbe); ) begin
    //  $display("got tbe=%s",tbe.name);
    //end
    
    $display("\nNesting:");
    `forenum(TwobitEnum,e) begin
      $display("  %s", e.name);
      `forenum(TwobitEnum,e)
        $display("    %s", e.name);
    end
    
  end

endmodule
