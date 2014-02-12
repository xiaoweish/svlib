// -------------------------------------------------------------
// This file defines svlib_private_base_pkg, a collection of
// functionality that is required by other parts of svLib.
// It also imports all the DPI functions that are required by
// other parts of the package.
// -------------------------------------------------------------

// -------------------------------------------------------------
//                       IMPORTANT NOTE
// -------------------------------------------------------------
// USER CODE SHOULD *NOT* IMPORT THIS PACKAGE. In this way,
// user code does not have access directly to the DPI functions,
// allowing svLib to take full control of the SV/C interaction.
// -------------------------------------------------------------

package svlib_private_base_pkg;

  `include "svlib_dpi_imports.sv"

  // Queue-of-strings is needed very widely in the library code,
  // so we create a convenient typedef for it here.
  typedef string qs[$];


  // Consistent mechanism to recover a queue of strings, of unknown length,
  // from data that's been set up on the DPI-C side. ~hnd~ is the C pointer,
  // supplied by some earlier DPI call, referencing the C string array data.
  // This function repeatedly calls svlib_dpi_imported_saBufNext to retrieve
  // one string from the C array and push the handle variable on to the next.
  // Flag ~keep_ss~ set: function appends to existing contents of ss.
  //    ~keep_ss~ clear: function deletes existing contents of ss before starting.
  //
  function automatic int svlib_private_getQS(input chandle hnd, ref qs ss, input bit keep_ss=0);
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


  // svlibBase: base class for almost all svlib classes. Provides the "Obstack"
  // mechanism that allows us to recycle unused objects.
  //
  class svlibBase;// #(parameter type T = int);
    svlibBase obstack_link;
  endclass


  virtual class Obstack #(parameter type T=int) extends svlibBase;
    local static svlibBase head;
    local static int constructed_ = 0;
    local static int get_calls_ = 0;
    local static int put_calls_ = 0;

    static function T get();
      T result;
      if (head == null) begin
        `ifdef SVLIB_NO_RANDSTABLE_NEW
        result = new();
        `else
        std::process p = std::process::self();
        string randstate = p.get_randstate();
        result = new();
        p.set_randstate(randstate);
        `endif
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

  // svlibErrorManager: singleton class to handle
  // per-process error management. A single instance
  // is stored as a static variable and can be returned
  // by the static getInstance method.
  //
  class svlibErrorManager extends svlibBase;

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
        singleton = Obstack#(svlibErrorManager)::get();
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

  //--------------------------------------------------------------
  // function scanUint64: not for public API! Assumes that the 
  // radix letter is OK, and the value-string has been stripped
  // of spaces and is reasonably sane. No handling of -ve numbers.
  // Result is always zero-filled to 64 bits.
  //--------------------------------------------------------------
  // This function reads from a string representation into a 64-bit value.
  // X/Z values are supported. Underscores are ignored. Otherwise, illegal
  // digits cause an error (0) to be returned and the result is undefined.
  // Unfortunately, sscanf can't be used because it doesn't tell us when 
  // it stopped, so we can't detect bad characters.
  // We already know that the characters are sure to be underscores,
  // hex digits, or X/Z. Leading and trailing underscores have already
  // been removed by the regex that got us here.

  function automatic bit scanUint64(int nBits, bit isSigned, string radixLetter, string v, output logic [63:0] result);
    logic [63:0] value;
    int radix, shift, msb;
    case (radixLetter)
      "h", "H", "x", "X" :
        begin radix= 16; shift = 4; end
      "o", "O" :
        begin radix = 8; shift = 3; end
      "d", "D" , "" :
        begin radix = 10; end // shift is not used
      "b", "B" :
        begin radix = 2; shift = 1; end
      default :
        return 0; // immediate fail
    endcase

    v = v.toupper();

    value = 0;

    if (radix == 10) begin
      // Special treatment for decimal numbers. If there is
      // an X or Z, it must be the one and only digit.
      // Leading and trailing underscores have already been
      // removed, so this test is valid.
      msb = 63;
      if (v == "X") begin
        result = 'x;
        return 1;
      end
      else if (v == "Z") begin
        result = 'z;
        return 1;
      end
      else begin
      
        foreach (v[i]) begin
          if (v[i] == "_") begin
            continue;
          end
          else if (v[i] inside {["0":"9"]}) begin
            value = 10*value + v[i] - "0";
          end
          else begin
            return 0;
          end
        end

      end
    end
    else begin
      // radix is 2/8/16

      msb = -1;
      foreach (v[i]) begin
        logic [3:0] digit;
        if (v[i] == "_") begin
          continue;
        end
        else begin
          msb += shift;
        end
        if (v[i] == "X") begin
          digit = 'x;
        end 
        else if (v[i] == "Z") begin
          digit = 'z;
        end
        else if (v[i] inside {["0":"9"]}) begin
          digit = v[i] - "0";
        end
        else if (v[i] inside {["A":"F"]}) begin
          digit = v[i] - "A" + 10;
        end
        else begin
          return 0;
        end
        if (digit >= radix) begin
          return 0;
        end
        value <<= shift;
        for (int b=0; b<shift; b++) value[b] = digit[b];
      end

    end

    // Protect against too many digits
    if (msb >= nBits) begin
      for (int i=nBits; i<=msb; i++) value[i] = 1'b0;
    end
    // Z/X fill to specified width
    if ($isunknown(value[msb])) begin
      for (int i=msb+1; i<nBits; i++) value[i] = value[msb];
    end
    if (isSigned) begin
      for (int i=nBits; i<64; i++) value[i] = value[nBits-1];
    end
    result = value;
    return 1;

  endfunction

endpackage
