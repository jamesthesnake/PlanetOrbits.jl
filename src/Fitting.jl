module Fitting

using ..DirectOrbits
using DirectImages

using Distributions
using StaticArrays

function planet_ln_like(convolved, priors, μ, plx, mjds, contrasts, platescale)

    # Samplers normally must supply their arguments as a vector
    function lnlike(phot, a, i, e, τ, ω, Ω)
        return lnlike((phot, a, i, e, τ, ω, Ω))
    end
    
    function lnlike(params)
        (phot, a, i, e, τ, ω, Ω) = params
        # The prior is given by the input distributions.
        # Sum their log pdf at this location
        ln_prior = zero(phot)
        for i in eachindex(params)
            pd = priors[i]
            param = params[i]
            ln_prior += logpdf(pd, param)
        end

        # return ln_prior

        # Construct an orbit with these parameters
        orbit = Orbit(a, i, e, τ, μ, ω, Ω, plx)
        # Then get the liklihood by multipliying together
        # the liklihoods at each epoch (summing the logs)
        ln_post = 0.0
        # Go through each image
        for I in eachindex(convolved)
            # Find the current position in arcseconds
            pos = SVector(0., 0., 0.)
            try
                pos = xyz(orbit, mjds[I])
            catch e
                if !(typeof(e) <: Real)
                    @warn "error looking up orbit" exception = e maxlog = 2
                end
            end
            # Get the value in the convolved images
            pos = SVector(pos[1], -pos[2])
            # I believe that the x-coordinate should be flipped because
            # image indices are opposite to sky coordinates

            # pos = SVector(-pos[2], pos[1])
            # pos = SVector(pos[2], -pos[1])

            phot_img = lookup_coord(convolved[I], pos, platescale)

            # NOTE: experimenting with flipped coords!
            # pos# .* SVector(1, 1, 1)
            # pos = SVector(-pos[2], pos[1])
            # phot_img = lookup_coord(convolved[I], pos, platescale)
            # Get the contrast at that location
            sep = sqrt(pos[1]^2 + pos[2]^2)
            σ = contrasts[I](sep / platescale)
            # Fallback if we fall off the edge of the image
            if isnan(σ)
                σ = 1e1
            end
            # The liklihood function from JB
            # ln_post += 1/2σ * (phot^2 - 2phot*phot_img)

            # Seems to be negative?
            ln_post_add  = -1/2σ * (phot^2 - 2phot*phot_img)
            # ln_post_add  = 1/2σ * (phot^2 - 2phot*phot_img)

            # Me trying something
            if isfinite(ln_post_add)
                ln_post += ln_post_add
            end
            # ln_post += -1/2σ * (phot^2 - 2phot*phot_img)

            # ln_post += log(
            #         1 / √(2π)σ * exp(
            #             -1 / 2((phot - phot_img)^2 / σ^2)
            #         )
            # )
        end
        # Fallback to a finite but bad value if we fall off the edge of the image
        # Is there a mathematically better way to express that we don't have this
        # information?
        if !isfinite(ln_post)
            @warn "non-finite posterior" maxlog = 20
            return Inf
        end
        # Multiply the liklihood by the prior
        return ln_post + ln_prior
        # return ln_prior
        # return ln_post

    end
    return lnlike
end

end