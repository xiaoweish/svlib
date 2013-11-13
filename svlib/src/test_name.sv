package Lib;
class S;
  protected string s;
  function string get(); return s; endfunction
  static function S create(string ss = "");
    S sss = new;
    sss.s = ss;
    return sss;
  endfunction
endclass
endpackage

package S;
function string get(); return "package"; endfunction
endpackage

module foo;

import S::*;
import Lib::*;

initial begin
  S s;
  s = S::create("me");
  $display("pkg \"%s\", member \"%s\"", get(), s.get());
end

endmodule
