
function bit cfgScalarInt::scan(string s);
  return scanVerilogInt(s, value);
endfunction

function cfgNode cfgNode::lookup(string path);
  int nextPos;
  Regex re = Obstack#(Regex)::obtain();
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
  Obstack#(Regex)::relinquish(re);
  foundPath = path.substr(0,nextPos-1);
  return (lastError == CFG_OK) ? foundNode : null;
endfunction
