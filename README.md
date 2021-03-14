# DirectOrbits.jl

Tools for solving Keplerian orbits in the context of direct imaging.
The primary use case is mapping Keplerian orbital elements into Cartesian
coordinates at different times. A Plots.jl recipe is included for easily plotting orbits.

You can combine this package with Distributions.jl for uncertanties
in each parameter, and also one of the MCMC packages like AffineInvariantMCMC.jl
for sampling orbits. The performance of this package is quite good, so it 
is reasonable to generate millions of orbits drawn from Distributions.jl
as part of a orbital fit routine. Examples of this will be included here
in the future.

See also [DirectImages.jl](//github.com/sefffal/DirectImages.jl)


# Usage
```julia
orbit = Orbit(
    a = 1.0,
    i = deg2rad(45),
    e = 0.25,
    τ = 0.0,
    μ = 1.0,
    ω = deg2rad(0),
    Ω = deg2rad(120),
    plx = 35.
)

# Display one full period of the orbit (requires `using Plots` beforehand)
plot(orbit, label="My Planet")
```
![Orbit Plot](docs/orbit-sample.png)

Note that by default the horizontal axis is flipped to match how it would look in the sky. The horizontal coordinates generated by these functions are not flipped in this way. If you use these coordinates to sample an image, you will have to either flip the image or negate the $x$ coordinate.


Get an Cartesian coordinate at a given epoch as an SVector() from the StaticArrays package.
```julia
julia> pos = xyz(orbit, 1.0) # at time in MJD (modified Julian days)
3-element StaticArrays.SArray{Tuple{3},Float64,1,3} with indices SOneTo(3):
  0.02003012254093835
  0.01072871196981525
 -0.019306398386215368
```

SVectors are chosen for the return values for easy composition with `CoordinateTransforms.jl` and `ImageTransformations.jl` packages.

**CAUTION**
If solving for the Eccentric Anomaly fails to converge, only a warning message (through `@warn`) is generated.
The function will return a point at the origin. This is to prevent a long running MCMC process from crashing when
infeasibile orbital parameters are chosen.


## Benchmarks

Sampling a position on a 2017 Core i7 laptop:
```julia
julia> @btime xyz(orbit,1.0)
  3.112 μs (23 allocations: 2.22 KiB)
```

Sampling 100,000 positions in well under a second:
```julia
julia> @time for _ in 1:100_000; xyz(orbit,1.0); end
  0.531661 seconds (2.30 M allocations: 216.675 MiB, 8.23% gc time)
```

A future goal is an option to use a slower solver without any allocations.