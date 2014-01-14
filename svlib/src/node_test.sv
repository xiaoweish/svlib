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
    nm = cfgNodeMap::create("root");
    root = nm;
    nm.addNode(cfgScalarInt::createNode("first", 1001));
    nm.addNode(cfgNodeMap::create("second_value"));
    nm.addNode(cfgScalarInt::createNode("third", 1003));
    nm.addNode(cfgNodeSequence::create("fourth"));
    $cast(ns, root.lookup("fourth"));
    ns.addNode(cfgScalarInt::createNode("", 13));
    ns.addNode(cfgScalarInt::createNode("", 14));
    ns.addNode(cfgScalarInt::createNode("", 15));
    $cast(nm, nm.value["second_value"]);
    nm.comments.push_back("second_value comment 1");
    nm.addNode(cfgScalarString::createNode("entryA", "valueA"));
    nm.addNode(cfgScalarString::createNode("entryB", "valueB"));
    nm.addNode(cfgNodeMap::create("section_C"));
    $cast(nm, nm.value["section_C"]);
    nm.comments.push_back("comment on section C: 1");
    nm.comments.push_back("comment on section C: 2");
    nm.addNode(cfgScalarInt::createNode("C_A", 500));
    nm.addNode(cfgScalarString::createNode("C_B", "' _ hello ** '"));
    $cast(nv, nm.lookup("C_A"));
    nv.comments.push_back("comment on C_A");
    
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
          err = root.getLastError();
          $display("lookup fail, error = %s", err.name);
        end
        else begin
          $display(node.sformat());
        end
      end
    end
    $fclose(f);
    
    begin
    
      cfgFileINI fi;
      cfgError_e err;
      
      fi = cfgFileINI::create("INI file my.ini");
      err = fi.openW("my.ini");
      $display("\nopenW: %s", err.name);
      
      err = fi.serialize(root.lookup("second_value"));
      $display("serialize: %s", err.name);
      
      err = fi.close();
      $display("close: %s\n", err.name);
      
      err = fi.openR("my.ini");
      $display("\nopenR: %s", err.name);
      
      root = fi.deserialize();
      void'(fi.close());
      $display();
      $display(root.sformat(1));
      $display();
      
      
      err = fi.openW("clone.ini");
      $display("\nopenW: %s", err.name);
      
      err = fi.serialize(root);
      $display("serialize: %s", err.name);
      
      err = fi.close();
      $display("close: %s\n", err.name);

    end
    
  end

endmodule
