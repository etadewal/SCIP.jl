wrap(base) = joinpath("wrapper", base * ".jl")

# used by Clang.jl
include(wrap("ctypes"))
include(wrap("CEnum"))
using .CEnum

# all type definitions
include(wrap("manual_commons"))
include(wrap("commons"))

# wrappers for scip headers
include(wrap("scip_bandit"))
include(wrap("scip_benders"))
include(wrap("scip_branch"))
include(wrap("scip_compr"))
include(wrap("scip_concurrent"))
include(wrap("scip_conflict"))
include(wrap("scip_cons"))
include(wrap("scip_copy"))
include(wrap("scip_cut"))
include(wrap("scip_datastructures"))
include(wrap("scip_debug"))
include(wrap("scip_dialog"))
include(wrap("scip_disp"))
include(wrap("scip_event"))
include(wrap("scip_expr"))
include(wrap("scip_general"))
include(wrap("scip_heur"))
include(wrap("scip_lp"))
include(wrap("scip_mem"))
include(wrap("scip_message"))
include(wrap("scip_nlp"))
include(wrap("scip_nodesel"))
include(wrap("scip_nonlinear"))
include(wrap("scip_numerics"))
include(wrap("scip_param"))
include(wrap("scip_presol"))
include(wrap("scip_pricer"))
include(wrap("scip_probing"))
include(wrap("scip_prob"))
include(wrap("scip_prop"))
include(wrap("scip_randnumgen"))
include(wrap("scip_reader"))
include(wrap("scip_relax"))
include(wrap("scip_reopt"))
include(wrap("scip_sepa"))
include(wrap("scip_sol"))
include(wrap("scip_solve"))
include(wrap("scip_solvingstats"))
include(wrap("scip_table"))
include(wrap("scip_timing"))
include(wrap("scip_tree"))
include(wrap("scip_validation"))
include(wrap("scip_var"))
