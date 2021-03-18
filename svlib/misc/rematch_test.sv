module top;

  initial begin
  
    svlib_pkg::Regex re;
    int start_pos;
    int match_start;
    int match_len;

    re = svlib_pkg::Regex::create();
    re.setRE("[A-Z]+");
    re.setStrContents("AAA_aaa_BBBB_bbb_ZZZZZZZZ,ZZ_ccc_DDDDD");

    start_pos=0;
    while (re.retest(.startPos(start_pos))) begin
      match_start=re.getMatchStart();
      match_len=re.getMatchLength();
      $display("%-8s %s",
                $sformatf("[%0d+:%0d]", match_start, match_len),
                    re.getMatchString());
      start_pos = match_start + match_len;
    end

  end

endmodule

