function automatic svlibErrorManager error_getManager();
  return svlibErrorManager::getInstance();
endfunction

function automatic void error_userHandling(bit user, bit setDefault=0);
  svlibErrorManager errorManager = error_getManager();
  errorManager.setUserHandling(user, setDefault);
endfunction

// Get the most recent error, and clear it from the error tracker
function automatic int error_getLast(bit clear = 1);
  svlibErrorManager errorManager = error_getManager();
  return errorManager.getLast(clear);
endfunction

// Get the string corresponding to a specific svlib error number.
// If err=0, get the error string for the most recent error,
// without clearing it.
function automatic string error_text(int err=0);
  svlibErrorManager errorManager = error_getManager();
  return errorManager.getText(err);
endfunction

// Get user-supplied details for the most recent error,
// without clearing it.
function automatic string error_details();
  svlibErrorManager errorManager = error_getManager();
  return errorManager.getDetails();
endfunction

// Get user-supplied details for the most recent error,
// without clearing it.
function automatic string error_fullMessage();
  svlibErrorManager errorManager = error_getManager();
  return errorManager.getFullMessage();
endfunction
