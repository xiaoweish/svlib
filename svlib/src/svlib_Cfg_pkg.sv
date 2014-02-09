`ifndef SVLIB_CFG_PKG__DEFINED
`define SVLIB_CFG_PKG__DEFINED

`include "svlib_macros.svh"

package svlib_Cfg_pkg;

  import svlib_Base_pkg::*;
  import svlib_Str_pkg::*;

  typedef enum {
    NODE_SCALAR, NODE_SEQUENCE, NODE_MAP,
    SCALAR_STRING, SCALAR_INT,
    FILE_INI, FILE_YAML
  } cfgObjKind_e;
  
  typedef enum { // Codes for errors from this package
  
    // No error, must be zero for ease of return value testing
    CFG_OK = 0,
    
    // Errors caused by generic (de)serialize operations
    CFG_SERIALIZE_NULL,                // Called serialize(null)

    // Errors caused by YAML serialize/deserialize operations
    CFG_YAML_NOT_YET_IMPLEMENTED,
    
    // Errors caused by file (de)serialize operations
    CFG_DESERIALIZE_FILE_NOT_READ,     // cfgFile object isn't opened for read
    CFG_SERIALIZE_FILE_NOT_WRITE,      // cfgFile object isn't opened for write
    
    // Errors caused by INI (de)serialize operations
    CFG_DESERIALIZE_INI_BAD_SYNTAX,    // INI file contents are bad
    CFG_SERIALIZE_INI_TOP_NOT_MAP,     // Root node must be a map
    CFG_SERIALIZE_INI_SECTION_NOT_MAP, // Each element of root map must be a scalar or map
    CFG_SERIALIZE_INI_NOT_SCALAR,      // Each element of section map must be a scalar
    
    // Errors caused by addNode operations
    CFG_ADDNODE_CANNOT_ADD,    // called on an inappropriate node object
    CFG_ADDNODE_DUPLICATE_KEY, // map already has the new node's key
    CFG_ADDNODE_NULL,          // trying to add a null node
    
    // Errors caused by file I/O
    CFG_OPEN_NO_FILE,        // attempt to open a file that doesn't exist
    CFG_CLOSE_NO_FILE,       // attempt to close when object has no file open
    CFG_OPEN_BAD_FILE_MODE,  // attempt to open a file with bad mode
    
    // Errors caused by scalar value set/get operations
    CFG_LOOKUP_NOT_SCALAR,   // node is not a scalar
    
    // Errors caused by cfgNode::lookup operations
    CFG_LOOKUP_BAD_SYNTAX,   // lookup string badly formed
    CFG_LOOKUP_MISSING_DOT,  // expected nothing or dot after [N]
    CFG_LOOKUP_NOT_SEQUENCE, // attempted [N] lookup into non-sequence
    CFG_LOOKUP_NOT_MAP,      // attempted .key lookup into non-map
    CFG_LOOKUP_NULL_NODE,    // found a null node in the hierarchy
    CFG_LOOKUP_NOT_FOUND     // [N] out of range, or .key not found
    
  } cfgError_e;

  // This enumeration actually represents a bit mask.
  typedef enum int {
    CFG_OPT_NONE = 'h0000
  } cfgOptions_e;
  
  virtual class svlibCfgBase extends svlibBase;
    pure virtual function cfgObjKind_e kind();
    protected string     name;
    protected cfgError_e lastError;
    protected string     lastErrorDetails;
    virtual function string     getName();             return name;             endfunction
    virtual function string     getLastErrorDetails(); return lastErrorDetails; endfunction
    virtual function cfgError_e getLastError();        return lastError;        endfunction
    virtual function string kind_str();
      cfgObjKind_e k = kind();
      return k.name;
    endfunction
    protected virtual function void cfgObjError(cfgError_e err);
      if (err == CFG_OK) return;
      // There was an error. Set up the error information:
      lastError = err;
      lastErrorDetails = errorDetails(err);
      // and throw the (optional) assertion error
      cfgNode_check_validity : 
        assert (err == CFG_OK) else
          $error("%s \"%s\": %s",
           kind_str(), name, lastErrorDetails);
    endfunction
    protected virtual function string errorDetails(cfgError_e err);
      return $sformatf("operation failed because %s", err.name);
    endfunction
  endclass
  
  virtual class cfgScalar extends svlibCfgBase;
    pure virtual function string       str();
    pure virtual function bit          scan(string s);
  endclass
  
  virtual class cfgNode extends svlibCfgBase;
    pure virtual function string       sformat(int indent = 0);
    pure virtual function cfgNode      childByName(string idx);
    string comments[$];
    string serializationHint;
    extern virtual function cfgNode lookup(string path);
    
    protected cfgNode          parent;
    protected cfgNode          foundNode;
    protected string           foundPath;
    virtual function void addNode(cfgNode nd);
      cfgObjError(CFG_ADDNODE_CANNOT_ADD);
    endfunction
    virtual function cfgNode    getFoundNode(); return foundNode;   endfunction
    virtual function string     getFoundPath(); return foundPath;   endfunction
    virtual function cfgNode    getParent();    return parent;      endfunction
  endclass
  
  virtual class cfgSerDes extends svlibCfgBase;
    pure virtual function cfgError_e serialize  (cfgNode node, int options=0);
    pure virtual function cfgNode    deserialize(int options=0);
  endclass
  
  virtual class cfgFile extends cfgSerDes;
    protected string filePath;
    protected int    fd;
    protected string mode;
    virtual function string getFilePath(); return filePath;     endfunction
    virtual function string getMode();     return mode;         endfunction
    virtual function int    getFD();       return fd;           endfunction
    protected virtual function cfgError_e open(string fp, string rw);
      void'(close());
      if (!(rw inside {"r", "w"})) begin
        return CFG_OPEN_BAD_FILE_MODE;
      end
      fd = $fopen(fp, rw);
      if (fd) begin
        filePath = fp;
        mode = rw;
      end
      return (mode != "") ? CFG_OK : CFG_OPEN_NO_FILE;
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
        return CFG_CLOSE_NO_FILE;
      end
    endfunction
  endclass
  
  class cfgNodeScalar extends cfgNode;
    `SVLIB_CFG_NODE_UTILS(cfgNodeScalar)
    cfgScalar value;
    function string sformat(int indent = 0);
      return $sformatf("%s%s", str_repeat(" ", indent), value.str());
    endfunction
    function cfgObjKind_e kind(); return NODE_SCALAR; endfunction
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
    function cfgObjKind_e kind(); return NODE_SEQUENCE; endfunction
    virtual function void addNode(cfgNode nd);
      if (nd == null) begin
        cfgObjError(CFG_ADDNODE_NULL);
        return;
      end
      nd.parent = this;
      value.push_back(nd);
      cfgObjError(CFG_OK);
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
    function cfgObjKind_e kind(); return NODE_MAP; endfunction
    virtual function void addNode(cfgNode nd);
      if (nd == null) begin
        cfgObjError(CFG_ADDNODE_NULL);
        return;
      end
      if (value.exists(nd.getName())) begin
        cfgObjError(CFG_ADDNODE_DUPLICATE_KEY);
      end
      nd.parent = this;
      value[nd.getName()] = nd;
      cfgObjError(CFG_OK);
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
    function string str();
      return $sformatf("%0d", value);
    endfunction
    extern function bit scan(string s);
    function cfgObjKind_e kind(); return SCALAR_INT; endfunction
    static function cfgScalarInt create(int v = 0);
      create = Obstack#(cfgScalarInt)::get();
      create.name = "";
      create.value = v;
    endfunction
    static function cfgNodeScalar createNode(string name, int v = 0);
      cfgNodeScalar ns = cfgNodeScalar::create(name);
      ns.value = cfgScalarInt::create(v);
      return ns;
    endfunction
  endclass
  
  class cfgScalarString extends cfgTypedScalar#(string);
    function string str();
      return get();
    endfunction
    function bit scan(string s);
      set(s);
      return 1;
    endfunction
    function cfgObjKind_e kind(); return SCALAR_STRING; endfunction
    static function cfgScalarString create(string v = "");
      create = Obstack#(cfgScalarString)::get();
      create.name = "";
      create.value = v;
    endfunction
    static function cfgNodeScalar createNode(string name, string v = "");
      cfgNodeScalar ns = cfgNodeScalar::create(name);
      ns.value = cfgScalarString::create(v);
      return ns;
    endfunction
  endclass
  
  class cfgFileINI extends cfgFile;
    function cfgObjKind_e kind(); return FILE_INI; endfunction
    static function cfgFileINI create(string name = "INI_FILE");
      create = Obstack#(cfgFileINI)::get();
      create.name = name;
    endfunction
    protected virtual function void writeComments(cfgNode node);
      if (node.comments.size() > 0) $fdisplay(fd);
      foreach (node.comments[i]) $fdisplay(fd, "# %s", node.comments[i]);
    endfunction
    
    protected function cfgError_e writeScalar(string key, cfgNodeScalar ns);
      writeComments(ns);
      $fdisplay(fd, "%s=%s", key, ns.sformat());
      return CFG_OK;
    endfunction
    
    protected function cfgError_e writeMap(string key, cfgNodeMap nm);
      cfgError_e err;
      $fdisplay(fd);
      writeComments(nm);
      $fdisplay(fd, "[%s]", key);
      foreach (nm.value[k2]) begin
        cfgNode nd = nm.value[k2];
        if (nm.value[k2].kind() != NODE_SCALAR) begin
          return CFG_SERIALIZE_INI_NOT_SCALAR;
        end
        else begin
          cfgNodeScalar ns;
          $cast(ns, nm.value[k2]);
          err = writeScalar(k2, ns);
          if (err != CFG_OK) return err;
        end
      end
      return CFG_OK;
    endfunction
    
    function cfgError_e serialize  (cfgNode node, int options=0);
      cfgNodeMap root;
      cfgError_e err;
      if (mode != "w")             return CFG_SERIALIZE_FILE_NOT_WRITE;
      if (node == null)            return CFG_SERIALIZE_NULL;
      if (node.kind() != NODE_MAP) return CFG_SERIALIZE_INI_TOP_NOT_MAP;
      // It's a map. Traverse it...
      writeComments(node);
      $cast(root, node);
      // For .INI, must write out all the scalars first.
      foreach (root.value[key]) begin
        if (root.value[key].kind() == NODE_SCALAR) begin
          cfgNodeScalar ns;
          $cast(ns, root.value[key]);
          err = writeScalar(key, ns);
          if (err != CFG_OK) return err;
        end
      end
      // Then write out all the maps - one level deep only!  
      foreach (root.value[key]) begin
        case (root.value[key].kind())
          NODE_SCALAR: ; // we've done those already
          NODE_MAP:
            begin
              cfgNodeMap nm;
              $cast(nm, root.value[key]);
              err = writeMap(key, nm);
              if (err != CFG_OK) return err;
            end
          default:
            return CFG_SERIALIZE_INI_SECTION_NOT_MAP;
        endcase
      end
      $fdisplay(fd);
      return CFG_OK;
    endfunction
    
    protected function void getRoot(ref cfgNodeMap it);
      if (it == null)
        it = cfgNodeMap::create("deserialized_INI_file");
    endfunction
    
    function cfgNode deserialize(int options=0);
    
      cfgNodeMap      root;
      cfgNodeMap      section;
      cfgNodeScalar   keyVal;
      string          value;
      qs              comments;
      Regex           reComment;
      Regex           reSection;
      Regex           reKeyVal;
      Str             strLine;
      
      if (mode != "r") begin
        cfgObjError(CFG_DESERIALIZE_FILE_NOT_READ);
        return null;
      end
      
      reComment = Obstack#(Regex)::get();
      reSection = Obstack#(Regex)::get();
      reKeyVal  = Obstack#(Regex)::get();
      strLine   = Obstack#(Str)::get();
      
      reComment.setRE("^\\s*[;#]\\s?(.*)$");
      reSection.setRE("^\\s*\\[\\s*(\\w+)\\s*\\]$");
      reKeyVal.setRE("^\\s*(\\w+)\\s*[=:]\\s*((\\w+)|(['\"])(.*)\\4)$");
      
      `foreach_line(fd, line, linenum) begin
      
        strLine.set(line);
        strLine.trim(Str::RIGHT);
        if (strLine.len() == 0) continue;
        
        if (reComment.test(strLine)) begin
          comments.push_back(reComment.getMatchString(1));
        end
        else if (reSection.test(strLine)) begin
          section = cfgNodeMap::create(reSection.getMatchString(1));
          section.comments = comments;
          comments.delete();
          getRoot(root);
          root.addNode(section);
        end
        else if (reKeyVal.test(strLine)) begin
          if (reKeyVal.getMatchStart(3) >=0) begin
            value = reKeyVal.getMatchString(3);
          end
          else begin
            value = reKeyVal.getMatchString(5);
          end
          keyVal = cfgScalarString::createNode(reKeyVal.getMatchString(1), value);
          keyVal.comments = comments;
          comments.delete();
          if (section) begin
            section.addNode(keyVal);
          end
          else begin
            getRoot(root);
            root.addNode(keyVal);
          end
        end
        else begin
          lastError = CFG_DESERIALIZE_INI_BAD_SYNTAX;
          //$display("bad syntax in line %0d \"%s\"", linenum, strLine.get());
        end
        
      end
      
      Obstack#(Regex)::put(reComment);
      Obstack#(Regex)::put(reSection);
      Obstack#(Regex)::put(reKeyVal);
      Obstack#(Str)::put(strLine);
      cfgObjError(lastError);
      return (lastError == CFG_OK) ? root : null;
      
    endfunction

 endclass
  
  class cfgFileYAML extends cfgFile;
    function cfgObjKind_e kind(); return FILE_YAML; endfunction
    static function cfgFileYAML create(string name = "YAML_FILE");
      create = Obstack#(cfgFileYAML)::get();
      create.name = name;
    endfunction
    function cfgError_e serialize  (cfgNode node, int options=0);
      return CFG_YAML_NOT_YET_IMPLEMENTED;
    endfunction
    function cfgNode deserialize(int options=0);
      cfgObjError(CFG_YAML_NOT_YET_IMPLEMENTED);
      return null;
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
    //   1: first path component, complete with leading/trailing whitespace
    //   |    2: first path component, with leading/trailing whitespace trimmed
    //   |    |       3: digits of index, trimmed, if index exists
    //   |    |       |                     4: relative-path '.' if it exists
    //   |    |       |                     |         5: name key, trimmed, if it exists
    //   |    |       |                     |         |               6: tail of name key (ignore this)
    //   |    |       |                     |         |               |                                7: tail
    //   1----2=======3************3========4***4=====5***************6#######################6*52----17--7
       "^(\\s*(\\[\\s*([[:digit:]]+)\\s*\\]|(\\.)?\\s*([^].[[:space:]]([^].[]*[^].[[:space:]]+)*))\\s*)(.*)$");

    nextPos = 0;
    foundNode = this;
    forever begin
      bit isIdx, isRel;
      string idx;
      cfgNode node;
      if (!re.retest(nextPos)) begin
        lastError = CFG_LOOKUP_BAD_SYNTAX;
        break;
      end
      isIdx = (re.getMatchStart(3) >= 0);
      isRel = isIdx || (re.getMatchStart(4) >= 0);
      if (!isRel && (nextPos > 0)) begin
        lastError = CFG_LOOKUP_MISSING_DOT;
        break;
      end
      if (foundNode == null) begin
        lastError = CFG_LOOKUP_NULL_NODE;
        break;
      end
      if (isIdx) begin
        if (foundNode.kind() != NODE_SEQUENCE) begin
          lastError = CFG_LOOKUP_NOT_SEQUENCE;
          break;
        end
        idx = re.getMatchString(3);
      end
      else begin
        if (foundNode.kind() != NODE_MAP) begin
          lastError = CFG_LOOKUP_NOT_MAP;
          break;
        end
        idx = re.getMatchString(5);
      end
      foundNode = foundNode.childByName(idx);
      if (foundNode == null) begin
        lastError = CFG_LOOKUP_NOT_FOUND;
        break;
      end
      nextPos = re.getMatchStart(7);
      if (nextPos == path.len()) begin
        lastError = CFG_OK;
        break;
      end
    end
    Obstack#(Regex)::put(re);
    foundPath = path.substr(0,nextPos-1);
    return (lastError == CFG_OK) ? foundNode : null;
  endfunction

endpackage

`endif
