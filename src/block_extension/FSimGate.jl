export FSimGate

# https://arxiv.org/pdf/1711.04789.pdf
# Google supremacy paper
mutable struct FSimGate{T<:Number} <: PrimitiveBlock{2}
    theta::T
    phi::T
end

function Base.:(==)(fs1::FSimGate, fs2::FSimGate)
    return fs1.theta == fs2.theta && fs1.phi == fs2.phi
end

function YaoBlocks.mat(::Type{T}, fs::FSimGate) where T
    θ, ϕ = fs.theta, fs.phi
    T[1 0          0          0;
     0 cos(θ)     -im*sin(θ) 0;
     0 -im*sin(θ) cos(θ)     0;
     0 0          0          exp(-im*ϕ)]
end

YaoBlocks.iparams_eltype(::FSimGate{T}) where T = T
YaoBlocks.getiparams(fs::FSimGate{T}) where T = (fs.theta, fs.phi)
function YaoBlocks.setiparams!(fs::FSimGate{T}, θ, ϕ) where T
    fs.theta = θ
    fs.phi = ϕ
    return fs
end
