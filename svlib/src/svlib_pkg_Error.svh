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
