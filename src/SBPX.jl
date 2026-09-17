module SBPX

import InteractiveUtils
import SummationByPartsOperators as SBPO
import SphericalSBPOperators

export available_sources, describe_sources, describe_derivative_operator,
       describe_spherical_operator

const SPHERICAL_SOURCE = :VretinarisSchnetter2026
const SPHERICAL_SOURCE_NOTE = "spherical collocated SBP4/SBP6 operators; constructed from MattssonNordström2004"

const SOURCE_YEAR_OVERRIDES = Dict(
    :LanczosLowNoise => 2008,
)

const SPECIAL_SOURCE_NOTES = Dict(
    :BeljaddLeFlochMishraParés2017 => "periodic central coefficients; no dedicated source-specific constructor helper",
    :Fornberg1998 => "generic periodic finite-difference stencil source",
    :GlaubitzNordströmÖffner2023 => "function-space SBP; use function_space_operator(...)",
    :Holoborodko2008 => "periodic low-noise differentiator",
    :LanczosLowNoise => "periodic low-noise differentiator; pass stencil_width",
    :MadayTadmor1989 => "Fourier viscosity source; use dissipation_operator(source, fourier_derivative_operator(...))",
    :Mattsson2017 => "upwind; constructor Mattsson2017(:central|:plus|:minus)",
    :MattssonNiemeläWinters2026 => "upwind, nonuniform grid; constructor MattssonNiemeläWinters2026(:central|:plus|:minus)",
    :SharanBradyLivescu2022 => "cut-cell source; constructor SharanBradyLivescu2022(alpha_left, alpha_right)",
    :Tadmor1989 => "Fourier viscosity source; use dissipation_operator(source, fourier_derivative_operator(...))",
    :Tadmor1993 => "Fourier viscosity source; use dissipation_operator(source, fourier_derivative_operator(...))",
    :TadmorWaagan2012Convergent => "Fourier viscosity source; use dissipation_operator(source, fourier_derivative_operator(...))",
    :TadmorWaagan2012Standard => "Fourier viscosity source; use dissipation_operator(source, fourier_derivative_operator(...))",
    :WilliamsDuru2024 => "upwind DRP source; constructor WilliamsDuru2024(:central|:plus|:minus)",
)

const FOURIER_DISSIPATION_SOURCES = Set((
    :MadayTadmor1989,
    :Tadmor1989,
    :Tadmor1993,
    :TadmorWaagan2012Convergent,
    :TadmorWaagan2012Standard,
))

const PERIODIC_DISSIPATION_SOURCES = Set((
    :BeljaddLeFlochMishraParés2017,
    :Fornberg1998,
    :Holoborodko2008,
    :LanczosLowNoise,
))

const PERIODIC_SOURCES = Set((
    :BeljaddLeFlochMishraParés2017,
    :Fornberg1998,
    :Holoborodko2008,
    :LanczosLowNoise,
))

"""
    available_sources(; sort_by=:year) -> Vector{Symbol}

Return the currently available Cartesian and spherical operator sources.

Most entries are coefficient sources provided by `SummationByPartsOperators.jl`.
`:VretinarisSchnetter2026` identifies the spherical collocated SBP4/SBP6
operator family provided by `SphericalSBPOperators.jl`.

Supported sort orders are `:year` and `:name`. The default is `:year`,
ordered from most recent to oldest. Results are always secondarily ordered by
name for stability. The publication year is used only for sorting and is not
included in the returned values.

`SourceOfCoefficientsCombination` is excluded because it is a composite wrapper
rather than a primary upstream source.
"""
function available_sources(; sort_by::Symbol=:year)
    source_types = InteractiveUtils.subtypes(SBPO.SourceOfCoefficients)
    source_entries = NamedTuple{(:name, :year), Tuple{Symbol, Int}}[]
    year_from_name(name::Symbol) = begin
        match_result = match(r"((?:19|20)\d{2})", String(name))
        if isnothing(match_result)
            haskey(SOURCE_YEAR_OVERRIDES, name) || throw(ArgumentError("could not infer year from source name $(repr(name))"))
            return SOURCE_YEAR_OVERRIDES[name]
        end
        parse(Int, match_result.captures[1])
    end

    for T in source_types
        base_type = Base.unwrap_unionall(T)
        nameof(base_type) === :SourceOfCoefficientsCombination && continue
        name = nameof(base_type)
        year = year_from_name(name)
        push!(source_entries, (name=name, year=year))
    end
    push!(source_entries, (name=SPHERICAL_SOURCE, year=2026))

    unique!(source_entries)

    if sort_by === :year
        sort!(source_entries; by=entry -> (-entry.year, String(entry.name)))
    elseif sort_by === :name
        sort!(source_entries; by=entry -> String(entry.name))
    else
        throw(ArgumentError("unsupported sort order $(repr(sort_by)); use :year or :name"))
    end

    return getproperty.(source_entries, :name)
end

function describe_sources(io::IO=stdout; sort_by::Symbol=:year)
    rows = [_source_row(name) for name in available_sources(; sort_by)]
    headers = ("Source", "Derivs", "Orders", "Dissipation", "Notes")
    grouped = Dict(
        "Spherical Sources" => Tuple[],
        "Fourier Sources" => Tuple[],
        "Periodic Sources" => Tuple[],
        "Nonperiodic / Specialized Sources" => Tuple[],
    )

    for row in rows
        category = _source_category(row.name)
        push!(grouped[category], (row.source, row.derivatives, row.operator_orders, row.dissipation, row.notes))
    end

    first_section = true
    for category in ("Spherical Sources", "Nonperiodic / Specialized Sources", "Periodic Sources", "Fourier Sources")
        section_rows = grouped[category]
        isempty(section_rows) && continue
        first_section || println(io)
        println(io, category)
        _print_table(io, headers, section_rows)
        first_section = false
    end

    return nothing
end

"""
    describe_derivative_operator(io::IO, source, derivative_order, accuracy_order; kwargs...)
    describe_derivative_operator(source, derivative_order, accuracy_order; kwargs...)

Print a readable description of the selected derivative operator with `h = 1`.
The output includes the interior stencil and, for nonperiodic operators, the
nontrivial left and right boundary closure stencils.

`source` may be either a source name `Symbol` such as `:MattssonNordström2004`
or a `SummationByPartsOperators.SourceOfCoefficients` instance.
For `:VretinarisSchnetter2026`, this dispatches to `describe_spherical_operator`
and `derivative_order` must be `1`.

Supported keyword arguments:
- `variant=:central` for upwind-capable sources
- `alpha_left=0.5`, `alpha_right=0.5` for `SharanBradyLivescu2022`
- `stencil_width=nothing` for `Holoborodko2008` and `LanczosLowNoise`
- `left_offset=nothing` for `Fornberg1998`
- `N=nothing`, `R=1`, and `p=2` for `VretinarisSchnetter2026`
"""
function describe_derivative_operator(io::IO, source, derivative_order::Integer,
                                      accuracy_order::Integer; kwargs...)
    if source === SPHERICAL_SOURCE
        derivative_order == 1 || throw(ArgumentError("$(SPHERICAL_SOURCE) provides first-derivative gradient/divergence operators; use derivative_order = 1"))
        return describe_spherical_operator(io, accuracy_order; kwargs...)
    end

    info = _derivative_operator_info(source, derivative_order, accuracy_order; kwargs...)
    source_name = String(info.source_name)

    println(io, "Source           : ", source_name)
    println(io, "Derivative order : ", derivative_order)
    println(io, "Accuracy order   : ", accuracy_order)
    println(io, "Grid spacing     : h = 1")
    println(io, "Operator family  : ", info.family)

    if !isempty(info.note)
        println(io, "Notes            : ", info.note)
    end

    println(io)
    println(io, "Interior stencil")
    _print_table(io, ("Offset", "Coefficient"), info.interior_rows)

    if !isempty(info.left_rows)
        println(io)
        println(io, "Left boundary closures")
        _print_table(io, ("Row", "Relative offsets", "Coefficients"), info.left_rows)
    end

    if !isempty(info.right_rows)
        println(io)
        println(io, "Right boundary closures")
        _print_table(io, ("Row", "Relative offsets", "Coefficients"), info.right_rows)
    elseif info.family == "periodic"
        println(io)
        println(io, "Boundary closures")
        println(io, "Periodic operator: no distinct boundary closure stencils.")
    end

    return nothing
end

"""
    describe_spherical_operator(io, accuracy_order; N=nothing, R=1, p=2)
    describe_spherical_operator(accuracy_order; N=nothing, R=1, p=2)

Print the origin closure, a representative interior stencil, and the outer-boundary
closure for the `VretinarisSchnetter2026` collocated spherical SBP operator family.
The report contains the even-field gradient `G_even`, odd-field derivative `G_odd`,
and covariant divergence `D`. `N` is the number of radial subintervals; its default
is the reproduction resolution from `SphericalSBPOperators.jl` (`32` for SBP4 and
`64` for SBP6).
"""
function describe_spherical_operator(io::IO, accuracy_order::Integer;
                                     N::Union{Nothing, Integer}=nothing,
                                     R=1,
                                     p::Integer=2)
    accuracy_order in (4, 6) || throw(ArgumentError("$(SPHERICAL_SOURCE) supports accuracy orders 4 and 6"))
    N_use = isnothing(N) ? (accuracy_order == 4 ? 32 : 64) : Int(N)
    origin_rows = _spherical_origin_closure_rows(accuracy_order)
    outer_rows = accuracy_order
    N_use >= origin_rows + outer_rows + 1 || throw(ArgumentError("N must be at least $(origin_rows + outer_rows + 1) to display distinct origin, interior, and outer-boundary stencils"))

    operators = SphericalSBPOperators.spherical_operators(
        SphericalSBPOperators.MattssonNordström2004();
        accuracy_order=Int(accuracy_order), N=N_use, R=R, p=Int(p), grid=:collocated,
        mode=SphericalSBPOperators.SafeMode(),
    )
    grid_spacing = operators.r[2] - operators.r[1]
    n = length(operators.r)
    interior_row = fld(origin_rows + 1 + n - outer_rows, 2)
    matrices = (("G_even", operators.Geven),
                ("G_odd", operators.Godd),
                ("D", operators.D))

    println(io, "Source           : ", SPHERICAL_SOURCE)
    println(io, "Accuracy order   : ", accuracy_order)
    println(io, "Grid             : collocated, r ∈ [0, ", R, "]")
    println(io, "Grid spacing     : h = ", _format_coefficient(grid_spacing))
    println(io, "Metric power     : p = ", p)
    println(io, "Underlying SBP   : MattssonNordström2004")
    println(io, "Notes            : ", SPHERICAL_SOURCE_NOTE)

    println(io, "\nOrigin closures")
    _print_table(io, ("Operator", "Row", "r", "Relative offsets", "Coefficients"),
                 _spherical_matrix_rows(matrices, operators.r, 1:origin_rows))

    println(io, "\nRepresentative interior stencils")
    println(io, "The covariant-divergence coefficients depend on radius; the displayed D row is representative.")
    _print_table(io, ("Operator", "Row", "r", "Relative offsets", "Coefficients"),
                 _spherical_matrix_rows(matrices, operators.r, interior_row:interior_row))

    println(io, "\nOuter-boundary closures")
    _print_table(io, ("Operator", "Row", "r", "Relative offsets", "Coefficients"),
                 _spherical_matrix_rows(matrices, operators.r, (n - outer_rows + 1):n))
    return nothing
end

function describe_spherical_operator(accuracy_order::Integer; kwargs...)
    return describe_spherical_operator(stdout, accuracy_order; kwargs...)
end

function describe_derivative_operator(source, derivative_order::Integer, accuracy_order::Integer;
                                      kwargs...)
    return describe_derivative_operator(stdout, source, derivative_order, accuracy_order; kwargs...)
end

function _source_row(name::Symbol)
    if name === SPHERICAL_SOURCE
        return (
            source=String(name),
            derivatives="G_even, G_odd, D",
            operator_orders="4,6",
            dissipation="-",
            notes=SPHERICAL_SOURCE_NOTE,
            name=name,
        )
    end

    derivative_orders, operator_orders = _source_operator_info(name)
    dissipation = _source_dissipation_info(name)
    notes = get(SPECIAL_SOURCE_NOTES, name, "")
    return (
        source=String(name),
        derivatives=derivative_orders,
        operator_orders=operator_orders,
        dissipation=dissipation,
        notes=notes,
        name=name,
    )
end

function _source_category(name::Symbol)
    if name === SPHERICAL_SOURCE
        return "Spherical Sources"
    elseif name in FOURIER_DISSIPATION_SOURCES
        return "Fourier Sources"
    elseif name in PERIODIC_SOURCES
        return "Periodic Sources"
    else
        return "Nonperiodic / Specialized Sources"
    end
end

function _source_operator_info(name::Symbol)
    if name === SPHERICAL_SOURCE
        return "G_even,G_odd,D", "SBP4,SBP6"
    elseif name === :BeljaddLeFlochMishraParés2017
        return "1,2,3", "d1:any; d2:any; d3:any"
    elseif name === :Fornberg1998
        return "1,2,3,4", "d1:1-10; d2:1-10; d3:1-10; d4:1-10"
    elseif name === :Holoborodko2008
        return "1,2", "d1:2,4; d2:2,4"
    elseif name === :LanczosLowNoise
        return "1,2", "d1:2,4; d2:2,4"
    elseif name in FOURIER_DISSIPATION_SOURCES
        return "-", "-"
    elseif name === :GlaubitzNordströmÖffner2023
        return "special", "function_space_operator(...)"
    end

    source = _instantiate_source(name)
    found = Dict{Int, Vector{Int}}()
    for derivative_order in 1:4
        accuracy_orders = Int[]
        for accuracy_order in 1:10
            try
                SBPO.derivative_operator(source, derivative_order, accuracy_order, 0.0, 1.0, 41)
                push!(accuracy_orders, accuracy_order)
            catch
            end
        end
        !isempty(accuracy_orders) && (found[derivative_order] = accuracy_orders)
    end

    isempty(found) && return "-", "-"

    derivs = join(sort!(collect(keys(found))), ",")
    orders = join(
        ["d$(d):" * join(found[d], ",") for d in sort!(collect(keys(found)))],
        "; ",
    )
    return derivs, orders
end

function _source_dissipation_info(name::Symbol)
    if name === SPHERICAL_SOURCE
        return "-"
    elseif name in FOURIER_DISSIPATION_SOURCES
        return "Fourier viscosity"
    elseif name in PERIODIC_DISSIPATION_SOURCES
        return "generic periodic (even order)"
    elseif name === :MattssonSvärdNordström2004
        return "source-specific nonperiodic"
    else
        return "-"
    end
end

function _instantiate_source(name::Symbol; variant::Symbol=:central, alpha_left::Real=0.5,
                             alpha_right::Real=0.5)
    if name === :Mattsson2017
        return SBPO.Mattsson2017(variant)
    elseif name === :MattssonNiemeläWinters2026
        return SBPO.MattssonNiemeläWinters2026(variant)
    elseif name === :WilliamsDuru2024
        return SBPO.WilliamsDuru2024(variant)
    elseif name === :SharanBradyLivescu2022
        return SBPO.SharanBradyLivescu2022(alpha_left, alpha_right)
    end
    T = getproperty(SBPO, name)
    return T()
end

function _derivative_operator_info(source, derivative_order::Integer, accuracy_order::Integer;
                                   variant::Symbol=:central, alpha_left::Real=0.5,
                                   alpha_right::Real=0.5, stencil_width::Union{Nothing, Int}=nothing,
                                   left_offset::Union{Nothing, Int}=nothing)
    source_instance, source_name = _resolve_source(source; variant, alpha_left, alpha_right)
    note = get(SPECIAL_SOURCE_NOTES, source_name, "")

    if source_name in FOURIER_DISSIPATION_SOURCES
        throw(ArgumentError("$(source_name) is a Fourier dissipation source, not a derivative operator source"))
    elseif source_name === :GlaubitzNordströmÖffner2023
        throw(ArgumentError("$(source_name) uses function_space_operator(...); local derivative stencils are not described here"))
    elseif source_name in PERIODIC_SOURCES
        coefficients = _periodic_coefficients(source_instance, source_name, derivative_order,
                                              accuracy_order; stencil_width, left_offset)
        return (
            source_name=source_name,
            family="periodic",
            note=note,
            interior_rows=_format_interior_rows(coefficients),
            left_rows=Tuple[],
            right_rows=Tuple[],
        )
    end

    operator = SBPO.derivative_operator(source_instance, derivative_order, accuracy_order,
                                        0.0, 200.0, 201)
    coefficients = operator.coefficients
    return (
        source_name=source_name,
        family="nonperiodic",
        note=note,
        interior_rows=_format_interior_rows(coefficients),
        left_rows=_format_boundary_rows(coefficients.left_boundary, :left),
        right_rows=_format_boundary_rows(coefficients.right_boundary, :right),
    )
end

function _resolve_source(source::Symbol; variant::Symbol=:central, alpha_left::Real=0.5,
                         alpha_right::Real=0.5)
    source_instance = _instantiate_source(source; variant, alpha_left, alpha_right)
    return source_instance, source
end

function _resolve_source(source::SBPO.SourceOfCoefficients; variant::Symbol=:central,
                         alpha_left::Real=0.5, alpha_right::Real=0.5)
    return source, nameof(typeof(source))
end

function _periodic_coefficients(source_instance, source_name::Symbol, derivative_order::Integer,
                                accuracy_order::Integer;
                                stencil_width::Union{Nothing, Int}=nothing,
                                left_offset::Union{Nothing, Int}=nothing)
    if source_name === :BeljaddLeFlochMishraParés2017
        return SBPO.periodic_central_derivative_coefficients(derivative_order, accuracy_order)
    elseif source_name === :Fornberg1998
        if isnothing(left_offset)
            return SBPO.periodic_derivative_coefficients(derivative_order, accuracy_order)
        end
        return SBPO.periodic_derivative_coefficients(derivative_order, accuracy_order, left_offset)
    elseif source_name === :Holoborodko2008 || source_name === :LanczosLowNoise
        kwargs = isnothing(stencil_width) ? (; ) : (; stencil_width)
        return SBPO.periodic_derivative_coefficients(source_instance, derivative_order,
                                                     accuracy_order; kwargs...)
    end

    throw(ArgumentError("unsupported periodic source $(repr(source_name))"))
end

function _format_interior_rows(coefficients)
    rows = Tuple{String, String}[]
    for (offset, coefficient) in _interior_stencil_pairs(coefficients)
        push!(rows, (_format_offset(offset), _format_coefficient(coefficient)))
    end
    return rows
end

function _interior_stencil_pairs(coefficients)
    pairs = Pair{Int, eltype(coefficients.lower_coef)}[]
    for (index, coefficient) in enumerate(coefficients.lower_coef)
        push!(pairs, -index => coefficient)
    end
    push!(pairs, 0 => coefficients.central_coef)
    for (index, coefficient) in enumerate(coefficients.upper_coef)
        push!(pairs, index => coefficient)
    end
    sort!(pairs; by=first)
    return pairs
end

function _format_boundary_rows(rows, side::Symbol)
    formatted = Tuple{String, String, String}[]
    for (row_index, row) in pairs(rows)
        offsets = _boundary_relative_offsets(row, row_index, side)
        push!(formatted, (
            side === :left ? "i=$(row_index)" : "i=N-$(row_index - 1)",
            join(_format_offset.(offsets), ", "),
            join(_format_coefficient.(collect(row.coef)), ", "),
        ))
    end
    return formatted
end

function _boundary_relative_offsets(row, row_index::Integer, side::Symbol)
    start = typeof(row).parameters[2]
    len = typeof(row).parameters[3]
    columns = collect(start:(start + len - 1))
    if side === :left
        return columns .- row_index
    elseif side === :right
        return row_index .- columns
    end
    throw(ArgumentError("unsupported boundary side $(repr(side))"))
end

function _format_offset(offset::Integer)
    if offset > 0
        return "+" * string(offset)
    end
    return string(offset)
end

function _format_coefficient(value)
    rational = rationalize(value)
    if iszero(rational)
        return "0"
    end
    denominator(rational) == 1 && return string(numerator(rational))
    return string(numerator(rational), "/", denominator(rational))
end

_spherical_origin_closure_rows(accuracy_order::Integer) =
    accuracy_order == 4 ? 7 : 10

function _spherical_matrix_rows(matrices, r, row_indices)
    rows = Tuple{String, String, String, String, String}[]
    for (name, matrix) in matrices
        for row_index in row_indices
            offsets, coefficients = _spherical_row_stencil(matrix, row_index)
            push!(rows, (
                name,
                "i=$(row_index)",
                _format_coefficient(r[row_index]),
                join(_format_offset.(offsets), ", "),
                join(_format_coefficient.(coefficients), ", "),
            ))
        end
    end
    return rows
end

function _spherical_row_stencil(matrix, row_index::Integer)
    offsets = Int[]
    coefficients = eltype(matrix)[]
    for column_index in axes(matrix, 2)
        coefficient = matrix[row_index, column_index]
        iszero(coefficient) && continue
        push!(offsets, column_index - row_index)
        push!(coefficients, coefficient)
    end
    return offsets, coefficients
end

function _print_table(io::IO, headers, rows)
    string_rows = [map(String, headers); [map(String, row) for row in rows]...]
    widths = [maximum(textwidth.(getindex.(string_rows, i))) for i in eachindex(headers)]
    separator = join([repeat("-", w) for w in widths], "-+-")

    println(io, join([rpad(String(headers[i]), widths[i]) for i in eachindex(headers)], " | "))
    println(io, separator)
    for row in rows
        cells = map(String, row)
        println(io, join([rpad(cells[i], widths[i]) for i in eachindex(cells)], " | "))
    end
end

end
