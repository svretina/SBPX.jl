@testitem "available_sources returns plain source names" tags=[:unit, :fast] begin
    sources = SBPX.available_sources()

    @test isa(sources, Vector{Symbol})
    @test !isempty(sources)
    @test allunique(sources)
end

@testitem "available_sources sorts by year by default" tags=[:unit, :fast] begin
    sources = SBPX.available_sources()
    year_from_name(name::Symbol) = begin
        match_result = match(r"((?:19|20)\d{2})", String(name))
        if isnothing(match_result)
            name === :LanczosLowNoise || error("missing test year mapping for $(repr(name))")
            return 2008
        end
        parse(Int, match_result.captures[1])
    end

    @test sources == sort(sources; by=name -> (-year_from_name(name), String(name)))
    @test year_from_name(first(sources)) >= year_from_name(last(sources))
end

@testitem "available_sources supports sorting by name" tags=[:unit, :fast] begin
    sources = SBPX.available_sources(; sort_by=:name)

    @test sources == sort(sources; by=String)
end

@testitem "available_sources exposes known upstream sources and years" tags=[:unit, :fast] begin
    sources = SBPX.available_sources()

    @test :Fornberg1998 in sources
    @test :MattssonNordström2004 in sources
    @test :WilliamsDuru2024 in sources
    @test :SourceOfCoefficientsCombination ∉ sources
end

@testitem "available_sources rejects unsupported sort orders" tags=[:unit, :fast] begin
    @test_throws ArgumentError SBPX.available_sources(; sort_by=:unsupported)
end

@testitem "available_sources tracks the current SBPO set size" tags=[:integration] begin
    @test length(SBPX.available_sources()) >= 20
end

@testitem "describe_sources prints a readable source table" tags=[:integration] begin
    output = sprint(io -> SBPX.describe_sources(io))

    @test occursin("Source", output)
    @test occursin("Derivs", output)
    @test occursin("Dissipation", output)
    @test occursin("Mattsson2017", output)
    @test occursin("WilliamsDuru2024", output)
end

@testitem "describe_derivative_operator prints nonperiodic boundary closures" tags=[:integration] begin
    output = sprint(io -> SBPX.describe_derivative_operator(io, :MattssonNordström2004, 1, 4))

    @test occursin("Source           : MattssonNordström2004", output)
    @test occursin("Interior stencil", output)
    @test occursin("Left boundary closures", output)
    @test occursin("Right boundary closures", output)
    @test occursin("i=1", output)
    @test occursin("i=N", output)
    @test occursin("Offset", output)
    @test occursin("/", output)
    @test !occursin("//", output)
end

@testitem "describe_derivative_operator prints periodic stencil info" tags=[:integration] begin
    output = sprint(io -> SBPX.describe_derivative_operator(io, :Fornberg1998, 1, 4))

    @test occursin("Source           : Fornberg1998", output)
    @test occursin("Operator family  : periodic", output)
    @test occursin("Interior stencil", output)
    @test occursin("Boundary closures", output)
    @test occursin("no distinct boundary closure stencils", output)
    @test occursin("/", output)
    @test !occursin("//", output)
    @test findfirst("-2", output) < findfirst("-1", output)
    @test occursin("-2     | 1/12", output)
    @test occursin("-1     | -2/3", output)
    @test occursin("+1     | 2/3", output)
    @test occursin("+2     | -1/12", output)
end

@testitem "describe_derivative_operator rejects Fourier dissipation sources" tags=[:unit, :fast] begin
    @test_throws ArgumentError SBPX.describe_derivative_operator(IOBuffer(), :Tadmor1989, 1, 2)
end
