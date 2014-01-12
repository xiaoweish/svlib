`ifndef SVLIB_CFG_PKG__DEFINED
`define SVLIB_CFG_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Cfg_pkg;

  import svlib_Base_pkg::*;
  import svlib_Str_pkg::*;

  typedef enum {SCALAR, SEQUENCE, MAP} cfgNodeKind_e;
  typedef enum {STRING, INT}           cfgScalarKind_e;
  typedef enum {
    CFG_OK = 0,  // Must be zero for ease of return value testing
    CFG_NOT_YET_IMPLEMENTED,
    CFG_NO_FILE,
    CFG_BAD_SYNTAX,
    CFG_MISSING_DOT,
    CFG_NOT_SEQUENCE,
    CFG_NOT_MAP,
    CFG_NULL_NODE,
    CFG_NOT_FOUND
  } cfgError_e;
  
  // This enumeration actually represents a bit mask.
  typedef enum int {
    CFG_OPT_NONE = 'h0000
  } cfgOptions_e;
  
  virtual class cfgScalar extends svlibBase;
    pure virtual function cfgScalarKind_e kind();
    pure virtual function string          str();
    pure virtual function bit             scan(string s);
  endclass
  
  virtual class cfgNode extends svlibBase;
    pure virtual function string        sformat(int indent = 0);
    pure virtual function cfgNodeKind_e kind();
    pure virtual function cfgNode       childByName(string idx);
    string comments[$];
    string serializationHint;
    extern virtual function cfgNode lookup(string path);
    
    protected string           name;
    protected cfgNode          parent;
    protected cfgNode          foundNode;
    protected string           foundPath;
    protected cfgError_e       lookupError;
    virtual function cfgError_e getLookupError(); return lookupError; endfunction
    virtual function cfgNode    getFoundNode();   return foundNode;   endfunction
    virtual function string     getFoundPath();   return foundPath;   endfunction
    virtual function cfgNode    getParent();      return parent;      endfunction
    virtual function string     getName();        return name;        endfunction
  endclass
  
  virtual class cfgSerDes extends svlibBase;
    pure virtual function cfgError_e serialize  (cfgNode node, int options=0);
    pure virtual function cfgError_e deserialize(cfgNode node, int options=0);
    protected string errorDetails;
    virtual function string getErrorDetails(); return errorDetails; endfunction
  endclass
  
  virtual class cfgFile extends cfgSerDes;
    protected string filePath;
    protected int    fd;
    protected string mode;
    virtual function string getFilePath();     return filePath;     endfunction
    virtual function string getMode();         return mode;         endfunction
    virtual function int    getFD();           return fd;           endfunction
    protected virtual function cfgError_e open(string fp, string rw);
      void'(close());
      if (rw inside {"r", "w"}) begin
        fd = $fopen(fp, rw);
        if (fd) begin
          filePath = fp;
          mode = rw;
        end
      end
      return (mode != "") ? CFG_OK : CFG_NO_FILE;
    endfunction
    virtual function cfgError_e openW(string fp); return open(fp, "w"); endfunction
    virtual function cfgError_e openR(string fp); return open(fp, "r"); endfunction
    virtual function cfgError_e close();
      mode = "";
      filePath = "";
      if (fd) begin
        $fclose(fd);
        fd = 0;
        return CFG_OK;
      end
      else begin
        return CFG_NO_FILE;
      end
    endfunction
  endclass
  
  class cfgNodeScalar extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeScalar)
    cfgScalar value;
    function string sformat(int indent = 0);
      return $sformatf("%s%s", str_repeat(" ", indent), value.str());
    endfunction
    function cfgNodeKind_e kind(); return SCALAR; endfunction
    function cfgNode childByName(string idx); return null; endfunction
  endclass

  class cfgNodeSequence extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeSequence)
    cfgNode value[$];
    function string sformat(int indent = 0);
      foreach (value[i]) begin
        if (i != 0) sformat = {sformat, "\n"};
        sformat = {sformat, str_repeat(" ", indent), "- \n", value[i].sformat(indent+1)};
      end
    endfunction
    function cfgNodeKind_e kind(); return SEQUENCE; endfunction
    virtual function void addNode(cfgNode nd);
      nd.parent = this;
      value.push_back(nd);
    endfunction
    function cfgNode childByName(string idx);
      int n = idx.atoi();
      if (n >= value.size() || n<0)
        return null;
      else
        return value[n];
    endfunction
  endclass

  class cfgNodeMap extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeMap)
    cfgNode value[string];
    function string sformat(int indent = 0);
      bit first = 1;
      foreach (value[s]) begin
        if (first)
          first = 0;
        else
          sformat = {sformat, "\n"};
        sformat = {sformat, str_repeat(" ", indent), s, " : \n", value[s].sformat(indent+1)};
      end
    endfunction
    function cfgNodeKind_e kind(); return MAP; endfunction
    virtual function void addNode(cfgNode nd);
      nd.parent = this;
      value[nd.getName()] = nd;
    endfunction
    function cfgNode childByName(string idx);
      if (!value.exists(idx))
        return null;
      else
        return value[idx];
    endfunction
  endclass
  
  virtual class cfgTypedScalar #(type T = int) extends cfgScalar;
    T value;
    virtual function T    get();    return value; endfunction
    virtual function void set(T v); value = v;    endfunction
  endclass
  
  class cfgScalarInt extends cfgTypedScalar#(int);
    `SVLIB_CLASS_UTILS(cfgScalarInt)
    function string str();
      return $sformatf("%0d", value);
    endfunction
    extern function bit scan(string s);
    function cfgScalarKind_e kind(); return INT; endfunction
    static function cfgScalarInt create(int v = 0);
      create = randstable_new();
      create.set(v);
    endfunction
    static function cfgNodeScalar createNode(string name, int v = 0);
      cfgNodeScalar ns = cfgNodeScalar::create(name);
      ns.value = cfgScalarInt::create(v);
      return ns;
    endfunction
  endclass
  
  class cfgScalarString extends cfgTypedScalar#(string);
    `SVLIB_CLASS_UTILS(cfgScalarString)
    function string str();
      return get();
    endfunction
    function bit scan(string s);
      set(s);
      return 1;
    endfunction
    function cfgScalarKind_e kind(); return STRING; endfunction
    static function cfgScalarString create(string v = "");
      create = randstable_new();
      create.value = v;
    endfunction
    static function cfgNodeScalar createNode(string name, string v = "");
      cfgNodeScalar ns = cfgNodeScalar::create(name);
      ns.value = cfgScalarString::create(v);
      return ns;
    endfunction
  endclass
  
  class cfgFileINI extends cfgFile;
    `SVLIB_CLASS_UTILS(cfgFileINI)
    static function cfgFileINI create(); return randstable_new(); endfunction
    function cfgError_e serialize  (cfgNode node, int options=0);
      cfgNodeMap root;
      if (mode != "w")        return CFG_NO_FILE;
      if (node == null)       return CFG_NULL_NODE;
      if (node.kind() != MAP) return CFG_NOT_MAP;
      // It's a map. Traverse it...
      foreach (node.comments[i]) begin
        $fdisplay(fd, "# %s", node.comments[i]);
      end
      $cast(root, node);
      foreach (root.value[key]) begin
        cfgNode nd = root.value[key];
        $fdisplay(fd);
        foreach (nd.comments[i]) begin
          $fdisplay(fd, "# %s", nd.comments[i]);
        end
        if (nd.kind() == SCALAR) begin
          cfgNodeScalar ns;
          $cast(ns, nd);
          $fdisplay(fd, "%s=%s", key, ns.sformat());
        end
        else if (nd.kind() == MAP) begin
          cfgNodeMap nm;
          $cast(nm, nd);
          $fdisplay(fd, "[%s]", key);
          foreach (nm.value[k2]) begin
            cfgNode n2 = nm.value[k2];
            foreach (n2.comments[i]) begin
              $fdisplay(fd, "# %s", n2.comments[i]);
            end
            if (n2.kind() == SCALAR) begin
              cfgNodeScalar ns;
              $cast(ns, n2);
              $fdisplay(fd, "%s=%s", k2, ns.sformat());
            end
            else begin
              return CFG_NOT_MAP;
            end
          end
        end
        else begin
          return CFG_NOT_MAP;
        end
      end
      $fdisplay(fd);
      return CFG_OK;
    endfunction
    
    function cfgError_e deserialize(cfgNode node, int options=0);
      return CFG_NOT_YET_IMPLEMENTED;
    endfunction
 endclass
  
  class cfgFileYAML extends cfgFile;
    `SVLIB_CLASS_UTILS(cfgFileYAML)
    static function cfgFileYAML create(); return randstable_new(); endfunction
    function cfgError_e serialize  (cfgNode node, int options=0);
      return CFG_NOT_YET_IMPLEMENTED;
    endfunction
    function cfgError_e deserialize(cfgNode node, int options=0);
      return CFG_NOT_YET_IMPLEMENTED;
    endfunction
 endclass
  
  function bit cfgScalarInt::scan(string s);
    return scanVerilogInt(s, value);
  endfunction

  function cfgNode cfgNode::lookup(string path);
    int nextPos;
    Regex re = Obstack#(Regex)::get();
    re.setStrContents(path);
    re.setRE(
    //     1: first path component, complete with leading/trailing whitespace
    //          2: first path component, with leading/trailing whitespace trimmed
    //                  3: digits of index, trimmed, if index exists
    //                                        4: relative-path '.' if it exists
    //                                                  5: name key, trimmed, if it exists
    //                                                                  6: tail of name key (ignore this)
    //                                                                                                   7: tail
    //     1----2=======3************3========4***4=====5***************6#######################6*52----17---7
         "^(\\s*(\\[\\s*([[:digit:]]+)\\s*\\]|(\\.)?\\s*([^].[[:space:]]([^].[]*[^].[[:space:]]+)*))\\s*)(.*$)");

    nextPos = 0;
    foundNode = this;
    forever begin
      bit isSeq, isRel;
      string idx;
      cfgNode node;
      if (!re.retest(nextPos)) begin
        lookupError = CFG_BAD_SYNTAX;
        break;
      end
      isSeq = (re.getMatchStart(3) >= 0);
      isRel = isSeq || (re.getMatchStart(4) >= 0);
      if (!isRel && (nextPos > 0)) begin
        lookupError = CFG_MISSING_DOT;
        break;
      end
      if (foundNode == null) begin
        lookupError = CFG_NULL_NODE;
        break;
      end
      if (isSeq) begin
        if (foundNode.kind() != SEQUENCE) begin
          lookupError = CFG_NOT_SEQUENCE;
          break;
        end
        idx = re.getMatchString(3);
      end
      else begin
        if (foundNode.kind() != MAP) begin
          lookupError = CFG_NOT_MAP;
          break;
        end
        idx = re.getMatchString(5);
      end
      foundNode = foundNode.childByName(idx);
      if (foundNode == null) begin
        lookupError = CFG_NOT_FOUND;
        break;
      end
      nextPos = re.getMatchStart(7);
      if (nextPos == path.len()) begin
        lookupError = CFG_OK;
        break;
      end
    end
    Obstack#(Regex)::put(re);
    foundPath = path.substr(0,nextPos-1);
    return (lookupError == CFG_OK) ? foundNode : null;
  endfunction

endpackage

`endif
