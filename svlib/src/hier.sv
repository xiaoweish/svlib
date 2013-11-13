module leaf;
  initial $display("leaf: \"%m\"");
endmodule

module mid;
  leaf \abc.&*( ();
  initial $display("mid: \"%m\"");
endmodule

module top;
  mid \middle% ();
  initial $display("top: \"%m\"");
endmodule
