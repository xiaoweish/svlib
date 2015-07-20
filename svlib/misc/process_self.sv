package pself_pkg;
  function int check_pself();
    std::process p;
    p = std::process::self();
    $display("%p", p);
    return (p!=null);
  endfunction
  int foobar = check_pself();
endpackage

module process_self;
  int foobar = pself_pkg::check_pself();
  
  initial begin
    int p_ok;
    p_ok = pself_pkg::check_pself();
    $display("initial block p_ok = %0d", p_ok);
    $display("decl init check = %0d", foobar);
    $display("pkg decl init check = %0d", pself_pkg::foobar);
  end

endmodule
