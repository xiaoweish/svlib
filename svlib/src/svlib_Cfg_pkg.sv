`ifndef SVLIB_CFG_PKG__DEFINED
`define SVLIB_CFG_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Cfg_pkg;

  import svlib_Str_pkg::*;

  typedef enum {SCALAR, SEQUENCE, MAP} nodeKind_e;
  typedef enum {STRING, INT}           scalarKind_e;
  
  virtual class ScalarBase;
    pure virtual function scalarKind_e kind();
    pure virtual function string       str();
    pure virtual function bit          scan(string s);
  endclass
  
  virtual class Scalar #(type T = int) extends ScalarBase;
    T value;
    virtual function T    get();    return value; endfunction
    virtual function void set(T v); value = v;    endfunction
  endclass
  
  virtual class Node;
    pure virtual function string sformat(int indent = 0);
    pure virtual function nodeKind_e kind();
  endclass
  
  class ScalarInt extends Scalar#(int);
    function string str();
      return $sformatf("%0d", value);
    endfunction
    extern function bit scan(string s);
    function scalarKind_e kind(); return INT; endfunction
    static function ScalarInt create(int v);
      create = new;
      create.set(v);
    endfunction
  endclass
  
  class ScalarString extends Scalar#(string);
    function string str();
      return get();
    endfunction
    function bit scan(string s);
      set(s);
      return 1;
    endfunction
    function scalarKind_e kind(); return STRING; endfunction
    static function ScalarString create(string v);
      create = new;
      create.value = v;
    endfunction
  endclass
  
  class NodeScalar extends Node;
    ScalarBase value;
    function string sformat(int indent = 0);
      return $sformatf("%s%s", {indent{" "}}, value.str());
    endfunction
    function nodeKind_e kind(); return SCALAR; endfunction
    static function NodeScalar create(ScalarBase v);
      create = new;
      create.value = v;
    endfunction
  endclass

  class NodeSequence extends Node;
    Node value[$];
    function string sformat(int indent = 0);
      foreach (value[i]) begin
        if (i != 0) sformat = {sformat, "\n"};
        sformat = {sformat, {indent{" "}}, "- \n", value[i].sformat(indent+1)};
      end
    endfunction
    function nodeKind_e kind(); return SEQUENCE; endfunction
  endclass

  class NodeMap extends Node;
    Node value[string];
    function string sformat(int indent = 0);
      bit first = 1;
      foreach (value[s]) begin
        if (first)
          first = 0;
        else
          sformat = {sformat, "\n"};
        sformat = {sformat, {indent{" "}}, s, " : \n", value[s].sformat(indent+1)};
      end
    endfunction
    function nodeKind_e kind(); return MAP; endfunction
  endclass
  
  function bit ScalarInt::scan(string s);
    return scanVerilogInt(s, value);
  endfunction
  
endpackage

`endif
