# quadratic constraints

MOI.supports_constraint(o::Optimizer, ::Type{SQF}, ::Type{<:BOUNDS}) = true

function MOI.add_constraint(o::Optimizer, func::SQF, set::S) where {S <: BOUNDS}
    if func.constant != 0.0
        error("SCIP does not support quadratic constraints with a constant offset.")
    end

    allow_modification(o)

    # affine terms
    linrefs = [VarRef(t.variable.value) for t in func.affine_terms]
    lincoefs = [t.coefficient for t in func.affine_terms]

    # quadratic terms
    quadrefs1 = [VarRef(t.variable_1.value) for t in func.quadratic_terms]
    quadrefs2 = [VarRef(t.variable_2.value) for t in func.quadratic_terms]
    # Divide coefficients by 2 iff they come from the diagonal:
    # Take coef * x * y as-is, but turn coef * x^2 into coef/2 * x^2.
    factor = 1.0 .- 0.5 * (quadrefs1 .== quadrefs2)
    quadcoefs = factor .* [t.coefficient for t in func.quadratic_terms]

    # range
    lhs, rhs = bounds(set)
    lhs = lhs === nothing ? -SCIPinfinity(o) : lhs
    rhs = rhs === nothing ?  SCIPinfinity(o) : rhs

    cr = add_quadratic_constraint(o.inner, linrefs, lincoefs,
                                  quadrefs1, quadrefs2, quadcoefs, lhs, rhs)
    ci = CI{SQF, S}(cr.val)
    register!(o, ci)
    register!(o, cons(o, ci), cr)
    return ci
end

function MOI.set(o::SCIP.Optimizer, ::MOI.ConstraintSet, ci::CI{SQF,S}, set::S) where {S <: BOUNDS}
    allow_modification(o)

    lhs, rhs = bounds(set)
    lhs = lhs === nothing ? -SCIPinfinity(o) : lhs
    rhs = rhs === nothing ?  SCIPinfinity(o) : rhs

    @SCIP_CALL SCIPchgLhsQuadratic(o, cons(o, ci), lhs)
    @SCIP_CALL SCIPchgRhsQuadratic(o, cons(o, ci), rhs)

    return nothing
end

function MOI.get(o::Optimizer, ::MOI.ConstraintFunction, ci::CI{SQF, S}) where {S <: BOUNDS}
    _throw_if_invalid(o, ci)
    c = cons(o, ci)

    affterms = AFF_TERM[]
    quadterms = QUAD_TERM[]

    nlinexprs = Ptr{Int32}()
    linexprs = Ptr{Ptr{SCIP_EXPR}}()
    lincoefs = Ptr{Cdouble}()
    nquadexprs = Ptr{Cint}()
    nbilinexprs = Ptr{Cint}()
    eigenvalues = Ptr{Ptr{Cdouble}}()
    eigenvectors = Ptr{Ptr{Cdouble}}()
    constant = Ptr{Cdouble}()

    expr = SCIPgetExprNonlinear(c)
    SCIPexprGetQuadraticData(expr, constant, nlinexprs, linexprs, lincoefs, nquadexprs, nbilinexprs, eigenvalues, eigenvectors)

    # variables that appear only linearly
    for i in 1:length(linexprs)
        push!(affterms, AFF_TERM(lincoefs[i], VI(ref(o, linexprs[i]).val)))
    end

    # variables that appear squared, and linearly
    quadvarterms = unsafe_wrap(Vector{SCIP_QUADVARTERM}, SCIPgetQuadVarTermsQuadratic(o, c), nquadexprs)
    for term in quadvarterms
        vi = VI(ref(o, term.var).val)
        push!(affterms, AFF_TERM(term.lincoef, vi))
        # multiply quadratic coefficients by 2!
        push!(quadterms, QUAD_TERM(2.0 * term.sqrcoef, vi, vi))
    end

    # bilinear terms (pair of different variables)
    bilinterms = unsafe_wrap(Vector{SCIP_BILINTERM}, SCIPgetBilinTermsQuadratic(o, c), nbilinexprs)
    for term in bilinterms
        # keep coefficients as they are!
        push!(quadterms, QUAD_TERM(term.coef, VI(ref(o, term.var1).val), VI(ref(o, term.var2).val)))
    end

    return SQF(quadterms, affterms, 0.0)
end

function MOI.get(o::Optimizer, ::MOI.ConstraintSet, ci::CI{SQF, S}) where {S <: BOUNDS}
    _throw_if_invalid(o, ci)
    lhs = SCIPgetLhsQuadratic(o, cons(o, ci))
    rhs = SCIPgetRhsQuadratic(o, cons(o, ci))
    return from_bounds(S, lhs, rhs)
end

function MOI.get(o::Optimizer, ::MOI.ConstraintPrimal, ci::CI{SQF, S}) where {S <: BOUNDS}
    activity = Ref{Cdouble}()
    @SCIP_CALL SCIPgetActivityQuadratic(o, cons(o, ci), SCIPgetBestSol(o), activity)
    return activity[]
end
