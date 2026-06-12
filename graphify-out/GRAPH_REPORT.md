# Graph Report - .  (2026-06-12)

## Corpus Check
- 4 files · ~393 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 12 nodes · 11 edges · 4 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]

## God Nodes (most connected - your core abstractions)
1. `recursively_list_pages()` - 4 edges
2. `SBPX` - 2 edges
3. `SBPX` - 2 edges
4. `list_pages()` - 2 edges
5. `TestItemRunner` - 1 edges
6. `Documenter` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.83
Nodes (3): Documenter, list_pages(), recursively_list_pages()

### Community 1 - "Community 1"
Cohesion: 0.67
Nodes (1): SBPX

### Community 2 - "Community 2"
Cohesion: 0.67
Nodes (2): SBPX, TestItemRunner

### Community 3 - "Community 3"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **2 isolated node(s):** `TestItemRunner`, `Documenter`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 3`** (2 nodes): `is_valid_string()`, `test-basic-test.jl`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SBPX` connect `Community 2` to `Community 0`?**
  _High betweenness centrality (0.145) - this node is a cross-community bridge._
- **What connects `TestItemRunner`, `Documenter` to the rest of the system?**
  _2 weakly-connected nodes found - possible documentation gaps or missing edges._