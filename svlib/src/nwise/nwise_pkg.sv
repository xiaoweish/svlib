`define NWISE_FACTOR_MAX 300

`define STRINGIFY(S) `"S`"

`define NWISE_BEGIN
  
`define NWISE_VAR_ENUM(TYPE,NAME) \
  rand TYPE NAME; \
  int __value__proxy__``NAME``__idx = value_proxy_next_idx(nwise_pkg::EnumUtils#(TYPE)::create(`STRINGIFY(NAME))); \
  constraint __c__value_proxy__``NAME``__ { \
    foreach (value_proxy[i]) { \
      (i == __value__proxy__``NAME``__idx) -> (value_proxy[i] == NAME); \
    } \
  }
  
`define NWISE_VAR_INT(TYPE,NAME,CONSTRAINT_SET) \
  class NWISE_VAR_INT_``NAME``_PROXY extends nwise_pkg::IntUtils#(TYPE); \
    constraint c {x inside CONSTRAINT_SET;} \
    static function VarUtils create(string _name); \
      NWISE_VAR_INT_``NAME``_PROXY obj = new(_name); \
      return obj; \
    endfunction \
    function new(string _name); super.new(_name); endfunction \
  endclass \
  rand TYPE NAME; \
  int __value__proxy__``NAME``__idx = value_proxy_next_idx(NWISE_VAR_INT_``NAME``_PROXY::create(`STRINGIFY(NAME))); \
  constraint __c__value_proxy__``NAME``__ { \
    NAME inside CONSTRAINT_SET; \
    foreach (value_proxy[i]) { \
      (i == __value__proxy__``NAME``__idx) -> (value_proxy[i] == NAME); \
    } \
  }
  
`define NWISE_END

package nwise_pkg;

  typedef struct {int covered; bit used[]; int value[];} factor_combo_t;

  typedef int qi[$];
    
  virtual class VarUtils;
    string name;
    function new(string _name); name = _name; endfunction
    pure virtual function string to_string(int v);
    pure virtual function qi all_values_list();
  endclass
  
  class EnumUtils#(parameter type E=int) extends VarUtils;
    function new(string _name); super.new(_name); endfunction
    static function qi all_values();
      E e = e.first;
      qi result = {};
      repeat (e.num) begin
        result.push_back(e);
        e = e.next;
      end
      return result;
    endfunction
    static function VarUtils create(string _name);
      EnumUtils#(E) obj = new(_name);
      return obj;
    endfunction
    function string to_string(int v);
      E e = E'(v);
      return e.name;
    endfunction
    function qi all_values_list();
      return all_values();
    endfunction
  endclass
  
  class IntUtils#(parameter type T=int) extends VarUtils;
    randc T x;
    function new(string _name); super.new(_name); endfunction
    function string to_string(int v);
      return $sformatf("%0d", v);
    endfunction
    function qi all_values_list();
      int tally[T];
      int count;
      forever begin
        void'(this.randomize());
        count++;
        if (!tally.exists(x)) begin
          tally[x] = 0;
        end
        else begin
          tally[x]++;
          if (tally[x] == 2) begin
            break;  // we got them all!
          end
        end
        assert (count <= 2*(`NWISE_FACTOR_MAX)) else
          $error("integral factor %s has too many values", name);
      end
      $write("%s :", name);
      foreach (tally[v]) begin
        all_values_list.push_back(v);
        $write(" %0d", v);
      end
      $display;
    endfunction
  endclass
  
  class Nwise_base;
  
    localparam n_tries = 20;
    
    // Number of factors to be considered
    int n_factors;
    
    // Requested n-wise order (2 = pairwise, etc)
    int n_wise;
    
    // Proxy variables locked to the values of user's factor variables
    rand int value_proxy[$];
    
    // For each factor, the complete list of possible values of that factor
    int factor_values[$][$];
    
    // Constraints limiting the factors' values to a temporary subset
    bit constrain_values_of_factor[$];
    int value_set_constraining_factor[$][$];
    
    // Class supporting type-agnostic printing of that factor
    VarUtils factor_utils[$];
    
    // The complete set of N-wise combinations that satisfy the constraints
    factor_combo_t all_combos[$];
    
    // Marker to say how many times the combo has been covered by a pattern
    int combo_used[$];
    
    // Set of generated patterns
    factor_combo_t pattern[$];
    
    function int value_proxy_next_idx(VarUtils utils);
      int idx = value_proxy.size();
      value_proxy.push_back(0);
      factor_values.push_back(utils.all_values_list());
      factor_utils.push_back(utils);
      constrain_values_of_factor.push_back(0);
      value_set_constraining_factor.push_back('{});
      n_factors = idx + 1;
      return idx;
    endfunction

    function bit can_merge(input factor_combo_t target, input factor_combo_t added);
      for (int i=0; i<n_factors; i++) begin
        if ( (target.value[i] != added.value[i]) && (target.used[i]) && (added.used[i]) ) begin
          // Incompatible, can't merge
          return 0;
        end
      end
      return 1;
    endfunction
    
    function bit merge(ref factor_combo_t target, /*const ref*/ input factor_combo_t added);
      if (!can_merge(target, added)) begin
        return 0;
      end
      // Do the merge
      for (int i=0; i<n_factors; i++) begin
        if (added.used[i]) begin
          target.value[i] = added.value[i];
          target.used[i] = 1;
        end
      end
      return 1;
    endfunction
  
    function factor_combo_t make_empty_combo();
      make_empty_combo.used  = new[n_factors];
      make_empty_combo.value = new[n_factors];
      make_empty_combo.covered = 0;
    endfunction

    function bit is_combo_complete(const ref factor_combo_t d);
      foreach (d.used[i]) begin
        if (!d.used[i]) return 0;
      end
      return 1;
    endfunction
    
    function void generate_combos(int nwise, int factors, factor_combo_t generator);
      if (nwise == 0) begin
        //if (check_combo(generator)) begin
          generator.covered = 0;
          all_combos.push_back(generator);
        //end
        //else begin
        //  $display("WARNING: Combination excluded by constraints: %s", combo_to_str(generator));
        //end
      end
      else begin
        for (int f = nwise-1; f < factors; f++) begin
          int fn = factor_values[f].size();
          generator.used[f] = 1;
          for (int i=0; i< fn; i++) begin
            generator.value[f] = factor_values[f][i];
            generate_combos(nwise-1, f, generator);
          end
          generator.used[f] = 0;
        end
      end
    endfunction
    
    function void generate_all_combos(int nwise);
      factor_combo_t combo = make_empty_combo();
      n_wise = nwise;
      all_combos.delete();
      generate_combos(nwise, n_factors, combo);
    endfunction
    
    function factor_combo_t pattern_from_object(bit update_proxy = 0);
      factor_combo_t ptn = make_empty_combo();
      if (update_proxy) begin
        void'(randomize(value_proxy));
      end
      foreach (ptn.used[i]) begin
        ptn.used[i] = 1;
      end
      ptn.value = value_proxy;
      return ptn;
    endfunction
    
    function string combo_to_str(factor_combo_t combo);
      string s = "{";
      bit first = 1;
      for (int f=0; f<n_factors; f++) begin
        if (combo.used[f]) begin
          if (!first) begin
            s = {s, ","};
          end
          s = $sformatf("%s %s:%s", s, factor_utils[f].name, factor_utils[f].to_string(combo.value[f]));
          first = 0;
        end
      end
      return {s, " }"};
    endfunction
    
    function void add_combo_to_constraints(factor_combo_t combo);
      int found[$];
      for (int f = 0; f < n_factors; f++) begin
        if (combo.used[f]) begin
          constrain_values_of_factor[f] = 1;
          found = value_set_constraining_factor[f].find_first_index() with (item==combo.value[f]);
          if (found.size() == 0) begin
            value_set_constraining_factor[f].push_back(combo.value[f]);
          end
        end
      end
    endfunction
    
    function void clear_constraints();
      foreach (constrain_values_of_factor[f]) begin
        constrain_values_of_factor[f] = 0;
        value_set_constraining_factor[f] = {};
      end
    endfunction
    
    function void constraints_from_combo(factor_combo_t combo);
      clear_constraints();
      add_combo_to_constraints(combo);
    endfunction
    
    function void print_constraints();
      bit first;
      string s;
      int vs[$];
      foreach (constrain_values_of_factor[f]) if (constrain_values_of_factor[f]) begin
        s = $sformatf("%s inside {", factor_utils[f].name);
        first = 1;
        vs = value_set_constraining_factor[f];
        foreach (vs[i]) begin
          if (!first) begin
            s = {s, ","};
          end
          s = $sformatf("%s %s", s, factor_utils[f].to_string(vs[i]));
          first = 0;
        end
        s = {s, " }"};
        $display(s);
      end
    endfunction
    
    function bit generate_constrained_pattern();
      return randomize() with {
        foreach (value_proxy[i]) {
          if (constrain_values_of_factor[i]) {
            value_proxy[i] inside {value_set_constraining_factor[i]};
          }
        }
      };
    endfunction
    
    // Can I find at least one set of values matching a given combo
    // that satisfies all the active constraints?
    // NOTE that if successful, this leaves the object containing
    // a suitable pattern
    function bit generate_combo_pattern(factor_combo_t combo);
      return randomize() with {
        foreach (value_proxy[i]) {
          if (combo.used[i]) {
            value_proxy[i] == combo.value[i];
          }
        }
      };
    endfunction
    
    // Compute redundancy score for a candidate 
    function int combo_redundancy(factor_combo_t pattern, factor_combo_t test);
      int r = 1;
      for (int i=0; i<n_factors; i++) begin
        if (pattern.used[i] && test.used[i] && (pattern.value[i] == test.value[i])) begin
          r *= 2;
        end
      end
      return r;
    endfunction
    function int pattern_redundancy(factor_combo_t pattern, factor_combo_t test);
      return combo_redundancy(pattern, test);
    endfunction
    
    function void make_patterns();
      factor_combo_t ptn;
      factor_combo_t best_ptn;
      int candidate_indices[$];
      int redundancy_score;
      int best_redundancy_score;
      bit ok;
      
      pattern.delete();
      foreach (all_combos[i]) begin
        all_combos[i].covered = 0;
      end
      
      all_combos.shuffle();
      
      foreach (all_combos[i]) begin
        if (all_combos[i].covered) continue;
        // Prepare the list of already-covered combos that could match
        candidate_indices.delete();
        foreach (all_combos[j]) begin
          if (all_combos[j].covered && can_merge(all_combos[i], all_combos[j])) begin
            candidate_indices.push_back(j);
          end
        end
        
        // Look for a minimum-redundancy solution
        best_redundancy_score = -1;
        $write("R:");
        repeat (n_tries) begin
          ok = generate_combo_pattern(all_combos[i]);
          if (!ok) begin
            $display("WARNING: Combination excluded by constraints: %s", combo_to_str(all_combos[i]));
            break;
          end
          ptn = pattern_from_object();
          redundancy_score = 0;
          foreach (candidate_indices[j]) begin
            redundancy_score += combo_redundancy(ptn, all_combos[candidate_indices[j]]);
          end
          foreach (pattern[j]) begin
            redundancy_score += pattern_redundancy(ptn, pattern[j]);
          end
          $write(" %0d", redundancy_score);
          if ((best_redundancy_score < 0) || (redundancy_score < best_redundancy_score)) begin
            best_redundancy_score = redundancy_score;
            best_ptn = ptn;
          end
        end
        $display();
        // Having got a pattern, use it to cover as many of the combos as possible
        //$display("got pattern %s", combo_to_str(ptn));
        foreach (all_combos[j]) begin
          if (can_merge(best_ptn, all_combos[j])) begin
            all_combos[j].covered++;
            best_ptn.covered++;
            //$display("covers [%0d] %s", candidate_indices[j], combo_to_str(all_combos[candidate_indices[j]]));
          end
        end
        pattern.push_back(best_ptn);
      end
    endfunction
    
    function void print_patterns();
      $display("====== %0d patterns for %0d-wise ======", pattern.size(), n_wise);
      foreach (pattern[p]) begin
        $display("%s (covers %0d combos)", combo_to_str(pattern[p]), pattern[p].covered);
      end
      $display("=====================================");
    endfunction
    
  endclass

endpackage
  
