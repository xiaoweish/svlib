`include "svlib_macros.sv"

module node_test;

  import svlib_Str_pkg::*;
  import svlib_Cfg_pkg::*;

  initial begin
  
    int f;
  
    cfgNodeMap      nm;
    cfgNodeScalar   nv;
    cfgNodeSequence ns;
    cfgNode         root, node;
    
    Regex  pathRE;
    string path, re;
    
    // build top-down
    nm = cfgNodeMap::create("root"); root = nm;
    nm.value["first"]  = cfgScalarInt::createNode(1001);
    nm.value["second"] = cfgScalarString::createNode("second_value");
    nm.value["third"]  = cfgScalarInt::createNode(1003);
    ns = cfgNodeSequence::create();
    nm.value["fourth"] = ns;
    ns.value.push_back(cfgScalarInt::createNode(13));
    ns.value.push_back(cfgScalarInt::createNode(14));
    ns.value.push_back(cfgScalarInt::createNode(15));
    
    $display("root : ");
    $display(root.sformat(1));
    
    $display();
    
    f = $fopen("numbers", "r");
    `foreach_line(f, s, n) begin
      int v;
      string show;
      bit ok;
      show = $sformatf("[%3d ] %14s", n, str_trim(s));
      ok = scanVerilogInt(s, v);
      if (ok) begin
        $display("%s = 32'h%h (%0d)", show, v, v);
      end
      else begin
        $display(show);
        //     1: everything from startpoint of string to end of first path component
        //          2: entire first path component with leading/trailing whitespace trimmed
        //                  3: digits of index, trimmed, if index exists
        //                                        4: relative-path '.' if it exists
        //                                                  5: name key, trimmed, if it exists
        //                                                                  6: tail of name key (ignore this)
        //                                                                                                   7: tail
        //     1----2=======3************3========4***4=====5***************6#######################6*52----17---7
        re = "^(\\s*(\\[\\s*([[:digit:]]+)\\s*\\]|(\\.)?\\s*([^].[[:space:]]([^].[]*[^].[[:space:]]+)*))\\s*)(.*$)";

        //path = ".babar[ 78 ] root  . completely fubar ";
        path = s;
        pathRE = regexMatch(path, re);
        if (pathRE==null) begin
          $display("  failed to match anything");
        end
        else begin
          int startPos;
          int matched;
          bit is_seq;
          bit is_rel;
          string summary;
          startPos = 0;
          forever begin
            matched = pathRE.retest(startPos);
            if (!matched) begin
              $display("  No match at startPos=%0d \"%s\"", startPos, str_trim(path.substr(startPos, path.len()-1), Str::RIGHT));
              break;
            end
            is_seq = (pathRE.getMatchStart(3) >= 0);
            is_rel = is_seq || (pathRE.getMatchStart(4) >= 0);
            summary = $sformatf("  @%-2d %s", startPos, is_rel ? "REL" : "ABS");
            if (is_seq) begin
              $display("%s SEQ [%s]", summary, pathRE.getMatchString(3));
            end
            else begin
              $display("%s MAP \"%s\"", summary, pathRE.getMatchString(5));
            end
            /*
            for (int i=0; i<pathRE.getMatchCount(); i++) begin
              $display("  $%0d: [%2d+:%2d] \"%s\"",
                             i,
                             pathRE.getMatchStart(i), 
                             pathRE.getMatchLength(i), 
                             pathRE.getMatchString(i));
            end
            */
            startPos = pathRE.getMatchStart(7);
            if (startPos == path.len()) break;
          end
        end
        node = root.lookup(path);
        if (node == null) begin
          cfgError_e err;
          err = root.getLookupError();
          $display("lookup fail, error = %s", err.name);
        end
        else begin
          $display(node.sformat());
        end
      end
    end
    $fclose(f);
    
  end

endmodule
