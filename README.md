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

### Spherical operators

SBPX exposes the spherical collocated SBP4/SBP6 family from
[`SphericalSBPOperators.jl`](https://github.com/svretina/SphericalSBPOperators.jl)
as `:VretinarisSchnetter2026`. Its report contains the origin closure, a
representative interior stencil, and the outer-boundary closure for `G_even`,
`G_odd`, and the covariant divergence `D`.

#### Exact SBP4 example with `h = 1`

The spherical report builds a collocated grid with `N + 1` nodes on `[0, R]`,
so its grid spacing is `h = R / N`. Set `R = N // 1` to make `h = 1` while
keeping the construction and printed coefficients in exact rational arithmetic.
The `//` notation creates a Julia rational number; do not use `32.0` when you
want the exact-coefficient report.

```julia
# SBP4 on r = 0, 1, ..., 32. All reported coefficients are rational.
describe_spherical_operator(4;
    N = 32,
    R = 32 // 1,
    p = 2,
)
```

The common source-inspection entry point provides the same report. This is
especially useful when `describe_derivative_operator` is already part of a
script or notebook workflow:

```julia
describe_derivative_operator(:VretinarisSchnetter2026, 1, 4;
    N = 32,
    R = 32 // 1,
    p = 2,
)
```

#### Exact SBP6 example with `h = 1`

The publication SBP6 reproduction resolution uses `N = 64`. Choosing the same
radius gives the exact unit-spaced grid `r = 0, 1, ..., 64`:

```julia
describe_derivative_operator(:VretinarisSchnetter2026, 1, 6;
    N = 64,
    R = 64 // 1,
    p = 2,
)
```

`p = 2` is the spherical metric power. The report supports the corresponding
cylindrical form with `p = 1`, but the examples above reproduce the usual
spherical case. The default resolutions are `N = 32` for SBP4 and `N = 64` for
SBP6; provide `R = N // 1` explicitly whenever a unit-step, rational report is
important.

#### Reading the spherical report

The header records the source family, requested accuracy, physical grid,
spacing, metric power, and the Cartesian SBP operator used internally. For the
examples above it says `h = 1`, which means the numbers in the tables are the
stencil coefficients themselves rather than coefficients divided by an
additional grid spacing.

Each table uses the following columns:

| Column | Meaning |
| --- | --- |
| `Operator` | `G_even` differentiates an even scalar field; `G_odd` differentiates an odd radial-flux field; `D` is the compatible covariant divergence. |
| `Row` | One-based row of the matrix, written as `i=k`. |
| `r` | Radius of that row. With `h = 1`, it is the corresponding integer grid coordinate. |
| `Relative offsets` | Column positions relative to the current row. For example, `-2, -1, +1, +2` uses values at `i-2`, `i-1`, `i+1`, and `i+2`. |
| `Coefficients` | Coefficients paired positionally with the offsets. They are printed as exact rational numbers. |

The report is divided into three regions:

- **Origin closures** are the special rows near `r = 0`. They enforce the
  even/odd parity conditions and regularize the coordinate singularity. For
  example, the first `G_even` row is empty because the derivative of an even
  field vanishes at the origin, while the first `D` row is the special
  removable-singularity divergence rule.

- **Representative interior stencils** show a row far from both closures.
  `G_even` and `G_odd` use the familiar translation-invariant Cartesian SBP
  stencil there. `D` is intentionally shown at one representative radius:
  its coefficients vary with `r` because it discretizes
  `∂ᵣu + p u/r`, not a constant-coefficient derivative.

- **Outer-boundary closures** are the final rows adjacent to `r = R`. They
  differ from the interior stencil so that the discrete SBP identity holds at
  the physical boundary.

For instance, an SBP4 origin row such as
`G_odd | i=1 | 0 | +1, +2 | 4/3, -1/6` means
`(G_odd u)_1 = (4/3)u_2 - (1/6)u_3` on the unit-step grid. The entries in every
other row should be read in exactly the same offset/coefficient pairing.

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
