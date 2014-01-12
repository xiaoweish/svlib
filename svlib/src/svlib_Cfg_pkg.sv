`ifndef SVLIB_CFG_PKG__DEFINED
`define SVLIB_CFG_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Cfg_pkg;

  import svlib_Base_pkg::*;
  import svlib_Str_pkg::*;

  typedef enum {SCALAR, SEQUENCE, MAP} cfgNodeKind_e;
  typedef enum {STRING, INT}           cfgScalarKind_e;
  typedef enum {
    CFG_OK,
    CFG_BAD_SYNTAX,
    CFG_MISSING_DOT,
    CFG_NOT_SEQUENCE,
    CFG_NOT_MAP,
    CFG_NULL_NODE,
    CFG_NOT_FOUND
  } cfgError_e;
  
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
  
  class cfgNodeScalar extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeScalar)
    cfgScalar value;
    function string sformat(int indent = 0);
      string sp = " ";
      return $sformatf("%s%s", {indent{sp}}, value.str());
    endfunction
    function cfgNodeKind_e kind(); return SCALAR; endfunction
    function cfgNode childByName(string idx); return null; endfunction
  endclass

  class cfgNodeSequence extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeSequence)
    cfgNode value[$];
    function string sformat(int indent = 0);
      string sp = " ";
      foreach (value[i]) begin
        if (i != 0) sformat = {sformat, "\n"};
        sformat = {sformat, {indent{sp}}, "- \n", value[i].sformat(indent+1)};
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
      string sp = " ";
      bit first = 1;
      foreach (value[s]) begin
        if (first)
          first = 0;
        else
          sformat = {sformat, "\n"};
        sformat = {sformat, {indent{sp}}, s, " : \n", value[s].sformat(indent+1)};
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
    static function cfgNodeScalar createNode(int v = 0);
      cfgNodeScalar ns = cfgNodeScalar::create();
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
    static function cfgNodeScalar createNode(string v = "");
      cfgNodeScalar ns = cfgNodeScalar::create();
      ns.value = cfgScalarString::create(v);
      return ns;
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
    //     1: everything from startpoint of string to end of first path component
    //          2: entire first path component with leading/trailing whitespace trimmed
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
