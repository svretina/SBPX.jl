# SBPX

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://svretina.github.io/SBPX.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://svretina.github.io/SBPX.jl/dev)
[![Test workflow status](https://github.com/svretina/SBPX.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/svretina/SBPX.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/svretina/SBPX.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svretina/SBPX.jl)
[![Lint workflow Status](https://github.com/svretina/SBPX.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/svretina/SBPX.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/svretina/SBPX.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/svretina/SBPX.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

`SBPX.jl` provides a small inspection layer on top of
[`SummationByPartsOperators.jl`](https://github.com/ranocha/SummationByPartsOperators.jl).
It is intended for exploring which upstream SBP operator sources are available
and for printing readable stencil information for selected derivative operators.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/svretina/SBPX.jl")
```

## Public API

After installation:

```julia
using SBPX
```

### `available_sources(; sort_by=:year)`

Returns the available coefficient sources from `SummationByPartsOperators.jl`
as `Symbol`s.

- Default sorting is by publication year, newest first.
- `sort_by=:name` sorts alphabetically.
- The returned values are plain source names such as `:MattssonNordström2004`
  or `:Fornberg1998`.

Example:

```julia
sources = available_sources()
sources_by_name = available_sources(sort_by=:name)
```

### `describe_sources(io=stdout; sort_by=:year)`

Prints a readable grouped summary of all available sources.

The table includes:

- derivative orders supported by each source
- operator orders currently available
- dissipation information
- notes about special constructor arguments or source behavior

The printed output is grouped into:

- `Nonperiodic / Specialized Sources`
- `Periodic Sources`
- `Fourier Sources`

Example:

```julia
describe_sources()
```

### `describe_derivative_operator(io, source, derivative_order, accuracy_order; kwargs...)`
### `describe_derivative_operator(source, derivative_order, accuracy_order; kwargs...)`

Prints detailed information for a selected derivative operator with `h = 1`.

For periodic operators, it prints the interior stencil.
For nonperiodic operators, it also prints the nontrivial left and right
boundary closure stencils.

The coefficients are shown exactly as rational strings such as `1/12` so they
can be copied directly into C++ or other languages.

`source` may be:

- a source name `Symbol`, for example `:MattssonNordström2004`
- an instantiated `SummationByPartsOperators.jl` source object

Supported keywords:

- `variant=:central` for upwind-capable sources such as `Mattsson2017`
- `alpha_left=0.5`, `alpha_right=0.5` for `SharanBradyLivescu2022`
- `stencil_width=nothing` for `Holoborodko2008` and `LanczosLowNoise`
- `left_offset=nothing` for `Fornberg1998`

Examples:

```julia
describe_derivative_operator(:MattssonNordström2004, 1, 4)

describe_derivative_operator(:Fornberg1998, 1, 4)

describe_derivative_operator(:Mattsson2017, 1, 4; variant=:plus)

describe_derivative_operator(
    :SharanBradyLivescu2022,
    1,
    2;
    alpha_left=0.3,
    alpha_right=0.7,
)
```

Example output:

```text
Source           : Fornberg1998
Derivative order : 1
Accuracy order   : 4
Grid spacing     : h = 1
Operator family  : periodic
Notes            : generic periodic finite-difference stencil source

Interior stencil
Offset | Coefficient
-------+------------
-2     | 1/12
-1     | -2/3
0      | 0
+1     | 2/3
+2     | -1/12

Boundary closures
Periodic operator: no distinct boundary closure stencils.
```

## Notes

- `SBPX.jl` is currently an inspection and discovery layer; it does not try to
  replace the construction routines in `SummationByPartsOperators.jl`.
- Fourier dissipation sources are listed by `describe_sources()`, but they are
  not derivative operator sources and therefore are rejected by
  `describe_derivative_operator(...)`.
