# Graph Report - .  (2026-09-17)

## Corpus Check
- 4 files · ~2,384 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 31 nodes · 49 edges · 8 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]

## God Nodes (most connected - your core abstractions)
1. `SBPX` - 21 edges
2. `_derivative_operator_info()` - 6 edges
3. `describe_sources()` - 5 edges
4. `describe_derivative_operator()` - 5 edges
5. `_format_interior_rows()` - 5 edges
6. `_source_row()` - 4 edges
7. `recursively_list_pages()` - 4 edges
8. `_source_operator_info()` - 3 edges
9. `_instantiate_source()` - 3 edges
10. `_resolve_source()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `SBPX` --defines--> `available_sources()`  [EXTRACTED]
  src/SBPX.jl → src/SBPX.jl  _Bridges community 2 → community 5_
- `SBPX` --defines--> `describe_derivative_operator()`  [EXTRACTED]
  src/SBPX.jl → src/SBPX.jl  _Bridges community 2 → community 1_
- `SBPX` --defines--> `_source_row()`  [EXTRACTED]
  src/SBPX.jl → src/SBPX.jl  _Bridges community 2 → community 6_
- `SBPX` --defines--> `_source_operator_info()`  [EXTRACTED]
  src/SBPX.jl → src/SBPX.jl  _Bridges community 2 → community 4_
- `SBPX` --defines--> `_format_interior_rows()`  [EXTRACTED]
  src/SBPX.jl → src/SBPX.jl  _Bridges community 2 → community 3_

## Communities

### Community 0 - "Community 0"
Cohesion: 0.38
Nodes (5): Documenter, list_pages(), recursively_list_pages(), SBPX, TestItemRunner

### Community 1 - "Community 1"
Cohesion: 0.4
Nodes (6): _boundary_relative_offsets(), _derivative_operator_info(), describe_derivative_operator(), _format_boundary_rows(), _periodic_coefficients(), _print_table()

### Community 2 - "Community 2"
Cohesion: 0.5
Nodes (3): InteractiveUtils, SBPX, SphericalSBPOperators

### Community 3 - "Community 3"
Cohesion: 0.5
Nodes (4): _format_coefficient(), _format_interior_rows(), _format_offset(), _interior_stencil_pairs()

### Community 4 - "Community 4"
Cohesion: 0.67
Nodes (3): _instantiate_source(), _resolve_source(), _source_operator_info()

### Community 5 - "Community 5"
Cohesion: 0.67
Nodes (3): available_sources(), describe_sources(), _source_category()

### Community 6 - "Community 6"
Cohesion: 1.0
Nodes (2): _source_dissipation_info(), _source_row()

### Community 7 - "Community 7"
Cohesion: 1.0
Nodes (0):

## Knowledge Gaps
- **4 isolated node(s):** `InteractiveUtils`, `SphericalSBPOperators`, `TestItemRunner`, `Documenter`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 6`** (2 nodes): `_source_dissipation_info()`, `_source_row()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 7`** (2 nodes): `year_from_name()`, `test-basic-test.jl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SBPX` connect `Community 2` to `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.406) - this node is a cross-community bridge._
- **Why does `_derivative_operator_info()` connect `Community 1` to `Community 2`, `Community 3`, `Community 4`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `InteractiveUtils`, `SphericalSBPOperators`, `TestItemRunner` to the rest of the system?**
  _4 weakly-connected nodes found - possible documentation gaps or missing edges._
