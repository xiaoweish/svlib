`include "svlib_macros.svh"

module node_test;

  import svlib_pkg::*;
  
  class TrialSerializableSmall;
  
    int x;
    string s;
    function void display();
      $display("TrialSerializableSmall::x=%0d", x);
      $display("TrialSerializableSmall::s=\"%s\"", s);
    endfunction
    
    `SVLIB_DOM_UTILS_BEGIN(TrialSerializableSmall)
      `SVLIB_DOM_FIELD_INT(x)
      `SVLIB_DOM_FIELD_STRING(s)
    `SVLIB_DOM_UTILS_END
  
  endclass
  
  class TrialSerializableTop;
  
    int x;
    string s;
    TrialSerializableSmall baby;
    
    function void display();
      $display("TrialSerializableTop::x=%0d", x);
      $display("TrialSerializableTop::s=\"%s\"", s);
      $display("TrialSerializableTop::baby...");
      if (baby == null) $display("null"); else baby.display();
    endfunction
    
    function new;
      baby = new;
    endfunction
    
    `SVLIB_DOM_UTILS_BEGIN(TrialSerializableTop)
      `SVLIB_DOM_FIELD_INT(x)
      `SVLIB_DOM_FIELD_STRING(s)
      `SVLIB_DOM_FIELD_OBJECT(baby)
    `SVLIB_DOM_UTILS_END
  
  endclass

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
        pathRE = regex_match(path, re);
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
          cfgError_enum err;
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
      cfgError_enum err;
      TrialSerializableTop tst;
      cfgNode nd;
      cfgNodeMap mp;
      
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
      
      tst = new;
      tst.s = "this is top.s";
      tst.x = 12345;
      tst.baby.s = "this is baby.s";
      tst.baby.x = 54321;
      $display("here is what I made:");
      tst.display();
      $display();
      
      nd = tst.toDOM("tst");
      $display("here is the DOM '%s'", nd.getName());
      $display(nd.sformat());
      $display();

      err = fi.openW("clone.ini");
      $display("\nopenW: %s", err.name);
      err = fi.serialize(nd);
      $display("serialize: %s", err.name);
      err = fi.close();
      $display("close: %s\n", err.name);

      tst = new;
      $display("here is the empty object:");
      tst.display();
      $display();
      $cast(mp, nd);
      tst.fromDOM(mp);
      $display("here is what I got back:");
      tst.display();
      $display();
      $display("here is the DOM '%s' after fromDOM", nd.getName());
      $display(nd.sformat());
      $display();
      
      tst = new;
      tst.baby=null;
      $display("here is the mangled object:");
      tst.display();
      $display();
      $cast(mp, nd);
      tst.fromDOM(mp);
      $display("here is what I got back:");
      tst.display();
      $display();
      $display("here is the DOM '%s' after fromDOM", nd.getName());
      $display(nd.sformat());
      $display();
      
    end
    
    begin
      longint walltime, mtime;
      Str haystack;
      Regex re;
      int n, m;
      longint manytime[10];
      
      walltime = sys_clockResolution();
      $display("clock resolution = %0d nanoseconds", walltime);
      foreach(manytime[i]) begin
        manytime[i] = sys_nsTime();
      end
      walltime = manytime[0];
      foreach(manytime[i]) begin
        $display("time[%1d] = %0d ns (delta=%5d)", i, manytime[i], manytime[i] - walltime);
        walltime = manytime[i];
      end
      
      m = 100;
      re = Regex::create("'([a-z]+),([a-z]+)'");
      haystack = Str::create();
      walltime = sys_nsTime();
      
      repeat (m) haystack.append("abc'def,ghi'jkl");
      repeat (100) begin
        n = re.substAll("'$2,$1'");
        assert (n==m);
      end
      $display("time taken = %8.6f sec", (sys_nsTime() - walltime)/1.0e9);
    end
    
    begin
      longint t;
      t = sys_dayTime();
      $display("Epoch time is %0d seconds", t);
      $display(sys_formatTime(t, "Today's time and date is %c"));
      $display("That's %s", sys_formatTime(t, "%Q"));
    
      for (int unsigned x=0; x<25; x++) begin
        int f;
        longint t;
        t = sys_nsTime();
        f = first_factor(x);
        t = sys_nsTime() - t;
        $display("Computed in %10.6f seconds", t/1.0e9);
        if (f < 0)
          $display("%0d is prime", x);
        else if (f>0)
          $display("%0d is divisible by %0d", x, f);
        else
          $display("WTF, %0d is not prime but cannot be factorized", x);
      end
    
    end
    
    begin
      sys_fileStat_s f;
      f = sys_fileStat("bad file");
    end
  end

  function automatic int first_factor(int unsigned N);
    string n_ones = str_repeat("1", N);
    Regex re = regex_match(n_ones, "^1?$|^(11+)(\\1+)$");
    if (re == null || (N>1 && re.getMatchLength(0)==0))
      return -1; // N is prime
    else begin
/*
      $display("match, $0=\"%s\"(%0d), $1=\"%s\"(%0d), $2=\"%s\"(%0d)",
                re.getMatchString(0), re.getMatchLength(0),
                re.getMatchString(1), re.getMatchLength(1),
                re.getMatchString(2), re.getMatchLength(2));
*/
      return re.getMatchLength(1); // return length of \1
    end
  endfunction

endmodule
