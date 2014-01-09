`include "svlib_macros.sv"

module node_test;

  import svlib_Str_pkg::*;
  import svlib_Cfg_pkg::*;

  initial begin
  
    int f;
  
    NodeMap      nm;
    NodeScalar   nv;
    NodeSequence ns;
    Node         root;
    
    // build top-down
    nm = new; root = nm;
    nm.value["first"]  = NodeScalar::create(ScalarInt::create(1001));
    nm.value["second"] = NodeScalar::create(ScalarString::create("second_value"));
    nm.value["third"]  = NodeScalar::create(ScalarInt::create(1003));
    ns = new; nm.value["fourth"] = ns;
    ns.value.push_back(NodeScalar::create(ScalarInt::create(13)));
    ns.value.push_back(NodeScalar::create(ScalarInt::create(14)));
    ns.value.push_back(NodeScalar::create(ScalarInt::create(15)));
    
    $display("root : ");
    $display(root.sformat(1));
    
    f = $fopen("numbers", "r");
    `foreach_line(f, s, n) begin
      int v;
      string show;
      bit ok;
      ok = scanVerilogInt(s, v);
      show = $sformatf("[%3d ] %14s", n, str_trim(s));
      if (ok)
        $display("%s = 32'h%h (%0d)", show, v, v);
      else
        $display("%s FAIL", show);
    end
    $fclose(f);

  end

endmodule
