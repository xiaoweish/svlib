`ifndef SVLIB_BASE_PKG__DEFINED
`define SVLIB_BASE_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Base_pkg;

  typedef string qs[$];
  
  import "DPI-C" function int SvLib_saBufNext(
                            inout  chandle hnd,
                            output string  path );

  function int SvLib_getQS(input chandle hnd, output qs ss, input bit keep_ss=0);
    int result;
    string s;
    if (!keep_ss)    ss.delete();
    if (hnd == null) return -1;
    forever begin
      result = SvLib_saBufNext(hnd, s);
      if (result != 0) return result;
      if (hnd == null) return 0;
      ss.push_back(s);
    end
  endfunction

  class svlib_base;// #(parameter type T = int);
    svlib_base obstack_link;
  endclass
  
  class PerProcess#(parameter type T=int) extends svlib_base;
  
    `SVLIB_CLASS_UTILS(PerProcess#(T))

    `ifdef INCA
      typedef string INDEX_T;
      protected function INDEX_T getIndex();
        return $sformatf("%p", std::process::self());
      endfunction
    `else
      typedef std::process INDEX_T;
      protected function INDEX_T getIndex();
        return std::process::self();
      endfunction
    `endif
    
    T valuePerProcess[INDEX_T];
    
    function void set(T value);
      valuePerProcess[getIndex()] = value;
    endfunction

    function bit is_set();
      return valuePerProcess.exists(getIndex());
    endfunction

    function T get();
      T value;
      INDEX_T i = getIndex();
      if (valuePerProcess.exists(i))
        value = valuePerProcess[i];
    endfunction
    
  endclass
  
  typedef PerProcess#(int) ppInt;
  
  // ppLastError can be created using plain old new(), because
  // only this package's RNG is affected and that doesn't matter.
  ppInt ppLastError = new();

  virtual class Obstack #(parameter type T=int) extends svlib_base;
    local static svlib_base head;
    local static int constructed_ = 0;
    local static int get_calls_ = 0;
    local static int put_calls_ = 0;
    
    static function T get();
      T result;
      if (head == null) begin
        result = T::create();
        constructed_++;
      end
      else begin
        $cast(result, head);//result = head;
        head = head.obstack_link;
      end
      get_calls_++;
      return result;
    endfunction
    static function void put(svlib_base t);
      put_calls_++;
      if (t == null) return;
      t.obstack_link = head;
      head = t;
    endfunction
    // debug/test only - DO NOT USE normally
    static function void stats(
        output int depth,
        output int constructed,
        output int get_calls,
        output int put_calls
      );
      svlib_base p = head;
      depth = 0;
      while (p != null) begin
        depth++;
        p = p.obstack_link;
      end
      constructed = constructed_;
      get_calls = get_calls_;
      put_calls = put_calls_;
    endfunction
  endclass

endpackage

`endif
