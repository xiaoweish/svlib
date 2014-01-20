`ifndef SVLIB_BASE_PKG__DEFINED
`define SVLIB_BASE_PKG__DEFINED

// -------------------------------------------------------------
// This file defines svlib_Base_pkg, a collection of underlying
// functionality that is required by other parts of svLib.
// It also imports all the DPI functions that are required by
// other parts of the package.
// User code should *not* import this package. In this way,
// user code does not have access directly to the DPI functions,
// allowing svLib to take full control of the SV/C interaction.
// -------------------------------------------------------------


`include "svlib_macros.sv"

package svlib_Base_pkg;

  `include "svlib_dpi_imports.sv"

  // Queue-of-strings is needed very widely in this library, so
  // we create a convenient typedef for it here.
  typedef string qs[$];
  

  function int svlib_private_getQS(input chandle hnd, output qs ss, input bit keep_ss=0);
    int result;
    string s;
    if (!keep_ss)    ss.delete();
    if (hnd == null) return 0;
    forever begin
      result = svlib_dpi_imported_saBufNext(hnd, s);
      if (result != 0) return result;
      if (hnd == null) return 0;
      ss.push_back(s);
    end
  endfunction

  class svlibBase;// #(parameter type T = int);
    svlibBase obstack_link;
  endclass
  
  class svlibErrorManager extends svlibBase;
  
    `SVLIB_CLASS_UTILS(svlibErrorManager)

    `ifdef INCA
      typedef string INDEX_T;
      protected function INDEX_T indexFromProcess(process p);
        return $sformatf("%p", p);
      endfunction
    `else
      typedef process INDEX_T;
      protected function INDEX_T indexFromProcess(process p);
        return p;
      endfunction
    `endif
    
    protected int valuePerProcess   [INDEX_T];
    protected bit pendingPerProcess [INDEX_T];
    protected bit userPerProcess    [INDEX_T];
    protected bit defaultUserBit;
    
    protected function INDEX_T getIndex();
      return indexFromProcess(process::self());
    endfunction
    
    static svlibErrorManager singleton = null;
    static function svlibErrorManager getInstance();
      if (singleton == null)
        singleton = randstable_new();
      return singleton;
    endfunction
    
    protected virtual function bit has(INDEX_T idx);
      return valuePerProcess.exists(idx);
    endfunction
    
    protected virtual function void newIndex(INDEX_T idx, int value=0);
      pendingPerProcess [idx] = (value != 0);
      valuePerProcess   [idx] = value;
      userPerProcess    [idx] = defaultUserBit;
    endfunction
    
    virtual function bit check(int value);
      INDEX_T idx = getIndex();
      if (!has(idx)) begin
        newIndex(idx, value);
      end
      else begin
        if (pendingPerProcess[idx]) begin
          svlibBase_check_unhandledError: assert (0) else
            $error("Not yet handled before next errorable call: %s",
                              svlibErrorDetails(valuePerProcess[idx])
            );
        end
        valuePerProcess[idx] = value;
        pendingPerProcess[idx] = (value != 0);
      end
      return !userPerProcess[idx];
    endfunction

    virtual function int get();
      INDEX_T idx = getIndex();
      if (has(idx)) begin
        pendingPerProcess[idx] = 0;
        return valuePerProcess[idx];
      end
      else begin
        return 0;
      end
    endfunction
    
    virtual function bit getUserHandling(bit getDefault=0);
      if (getDefault) begin
        return defaultUserBit;
      end else begin
        INDEX_T idx = getIndex();
        if (!has(idx))
          return defaultUserBit;
        else
          return userPerProcess[idx];
      end
    endfunction
    
    virtual function void setUserHandling(bit user, bit setDefault=0);
      if (setDefault) begin
        defaultUserBit = user;
      end
      else begin
        INDEX_T idx = getIndex();
        if (!has(idx)) begin
          newIndex(idx, 0);
        end
        userPerProcess[idx] = user;
      end
    endfunction
    
    virtual function qs report();
      report.push_back($sformatf("----\\/---- Per-Process Error Manager ----\\/----"));
      report.push_back($sformatf("  Default user-mode = %b", defaultUserBit));
      if (userPerProcess.num) begin
        report.push_back($sformatf("  user pend errno err"));
        foreach (userPerProcess[idx]) begin
          report.push_back($sformatf("    %b    %b  %4d  %s",
                        userPerProcess[idx], pendingPerProcess[idx],
                           valuePerProcess[idx], svlibErrorString(valuePerProcess[idx])));
        end
      end
      report.push_back($sformatf("----/\\---- Per-Process Error Manager ----/\\----"));
    endfunction
    
  endclass
  
  svlibErrorManager errorManager = svlibErrorManager::getInstance();
  
  function automatic void svlibUserHandlesErrors(bit user, bit setDefault=0);
    errorManager.setUserHandling(user, setDefault);
  endfunction

  function automatic int svlibLastError();
    return errorManager.get(); 
  endfunction
  
  // Get the string corresponding to a specific C error number.
  // If err=0, use the most recent error instead.
  function automatic string svlibErrorString(int err=0);
    if (err == 0)
      err = svlibLastError();
    return svlib_dpi_imported_getCErrStr(err);
  endfunction
  
  function automatic string svlibErrorDetails(int err=0);
    if (err == 0)
      err = svlibLastError();
    return $sformatf("errno=%0d (%s)", err, svlib_dpi_imported_getCErrStr(err));
  endfunction
  
  virtual class Obstack #(parameter type T=int) extends svlibBase;
    local static svlibBase head;
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
        $cast(result, head);
        head = head.obstack_link;
      end
      get_calls_++;
      return result;
    endfunction
    static function void put(svlibBase t);
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
      svlibBase p = head;
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
