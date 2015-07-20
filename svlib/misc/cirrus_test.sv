module top;

  import svlib_pkg::*;


  initial begin
      Regex re;
   Str str;
   string text;
   bit result;
   bit done;
   int start_pos;
   int iterations;
   int len;
   int match_string;
   int match_start;
   int match_len;
   int match_index;
   int j, k;
   
   str=Str::create();
   re=Regex::create();
   re.setRE("([A-Z]+)[^A-Z]+([A-Z]+)[^A-Z]+([A-Z]+)[^A-Z]+([A-Z]+)");
   text="AAA_aaa_BBBB_bbb_ZZZZZZZZZZ_ccc_DDDDD";
   str.set(text);
   re.setStr(str);
   
   match_index=0;
   start_pos=0;
   result=re.retest(.startPos(start_pos));
   $display("result=%0d, start_pos=%0d, iterations=%0d", result, start_pos, iterations);
   iterations++;
   for (int i=0; i<7; i++)
      begin
      match_index=i;
      match_string=re.getMatchString(i);
      match_start=re.getMatchStart(i);
      match_len=re.getMatchLength(i);
      text=str.range(match_start, match_len);
      $display("%s, %0d, %0d, %s", match_string, match_start, match_len, text);
      end

  end

endmodule

