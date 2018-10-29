function raise(errcode, message_buffer)
    if errcode[] != 0
        if errcode[] == 1
            error("CoolProp: ", unsafe_string(convert(Ptr{UInt8}, pointer(message_buffer))))
        elseif errcode[] == 2
            error("CoolProp: message buffer too small")
        else # == 3
            error("CoolProp: unknown error")
        end
    end
end
# ---------------------------------
#        Low-level access
# ---------------------------------

"""
    AbstractState_factory(backend::AbstractString, fluids::AbstractString)

Generate an AbstractState instance return an integer handle to the state class generated to be used in the other low-level accessor functions.

# Arguments
* `backend`: The backend you will use could be: `["HEOS", "REFPROP", "INCOMP", "IF97", "TREND", "HEOS&TTSE", "HEOS&BICUBIC", "SRK", "PR", "VTPR"]` etc.
* `fluids`: '&' delimited list of fluids. To get a list of possible values call `get_global_param_string(key)` with `key` one of the following: `["FluidsList", "incompressible_list_pure", "incompressible_list_solution", "mixture_binary_pairs_list", "predefined_mixtures"]`, also there is a list in CoolProp online documentation [List of Fluids](http://www.coolprop.org/fluid_properties/PurePseudoPure.html#list-of-fluids), or simply type `?CoolProp_fluids`

# Example
```julia
julia> HEOS = AbstractState_factory("HEOS", "R245fa");
julia> TTSE = AbstractState_factory("HEOS&TTSE", "R245fa");
julia> BICU = AbstractState_factory("HEOS&BICUBIC", "R245fa");
julia> SRK = AbstractState_factory("SRK", "R245fa");
julia> PR = AbstractState_factory("PR", "R245fa");
```
"""
function AbstractState_factory(backend::AbstractString, fluids::AbstractString)
    AbstractState = ccall( (:AbstractState_factory, "CoolProp"), Clong, (Cstring, Cstring, Ref{Clong}, Ptr{UInt8}, Clong), backend, fluids, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return AbstractState
end

"""
    AbstractState_free(handle::Clong)

Release a state class generated by the low-level interface wrapper.

# Arguments
* `handle`: The integer handle for the state class stored in memory
"""
function AbstractState_free(handle::Clong)
    ccall( (:AbstractState_free, "CoolProp"), Void, (Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_set_fractions(handle::Clong, fractions::Array{Float64})

Set the fractions (mole, mass, volume) for the AbstractState.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `fractions`: The array of fractions

# Example
```julia
julia> handle = AbstractState_factory("HEOS", "Water&Ethanol");
julia> pq_inputs = get_input_pair_index("PQ_INPUTS");
julia> t = get_param_index("T");
julia> AbstractState_set_fractions(handle, [0.4, 0.6]);
julia> AbstractState_update(handle, pq_inputs, 101325, 0);
julia> AbstractState_keyed_output(handle, t)
352.3522212991724
julia> AbstractState_free(handle);
```
"""
function AbstractState_set_fractions(handle::Clong, fractions::Array{Float64})
    ccall( (:AbstractState_set_fractions, "CoolProp"), Void, (Clong, Ptr{Cdouble}, Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, fractions, length(fractions), errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_update(handle::Clong, input_pair::Clong, value1::Real, value2::Real)
    AbstractState_update(handle::Clong, input_pair::AbstractString, value1::Real, value2::Real)

Update the state of the AbstractState.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `input_pair::Clong`: The integer value for the input pair obtained from get_input_pair_index(param::AbstractString)
* `input_pair::AbstractString`: The name of an input pair
* `value1`: The first input value
* `value2`: The second input value

# Example
```julia
julia> handle = AbstractState_factory("HEOS", "Water&Ethanol");
julia> pq_inputs = get_input_pair_index("PQ_INPUTS");
julia> t = get_param_index("T");
julia> AbstractState_set_fractions(handle, [0.4, 0.6]);
julia> AbstractState_update(handle, pq_inputs, 101325, 0);
julia> AbstractState_keyed_output(handle, t)
352.3522212991724
julia> AbstractState_free(handle);
```
"""
function AbstractState_update(handle::Clong, input_pair::Clong, value1::Real, value2::Real)
    ccall( (:AbstractState_update, "CoolProp"), Void, (Clong, Clong, Cdouble, Cdouble, Ref{Clong}, Ptr{UInt8}, Clong), handle, input_pair, value1, value2, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

function AbstractState_update(handle::Clong, input_pair::AbstractString, value1::Real, value2::Real)
    AbstractState_update(handle::Clong, get_input_pair_index(input_pair), value1::Real, value2::Real)
    return nothing
end

"""
    AbstractState_keyed_output(handle::Clong, param::Clong)

Get an output value from the `AbstractState` using an integer value for the desired output value.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `param::Clong`: param The integer value for the parameter you want

# Note
See `AbstractState_output`
"""
function AbstractState_keyed_output(handle::Clong, param::Clong)
    output = ccall( (:AbstractState_keyed_output, "CoolProp"), Cdouble, (Clong, Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, param, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    if output == -Inf
        error("CoolProp: no correct state has been set with AbstractState_update")
    end
    return output
end

"""
    AbstractState_output(handle::Clong, param::AbstractString)

Get an output value from the `AbstractState` using an integer value for the desired output value. It is a convenience function that call `AbstractState_keyed_output`

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `param::AbstractString`: The name for the parameter you want
"""
function AbstractState_output(handle::Clong, param::AbstractString)
    return AbstractState_keyed_output(handle, get_param_index(param))
end


"""
    AbstractState_specify_phase(handle::Clong, phase::AbstractString)

Specify the phase to be used for all further calculations.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `phase`: The string with the phase to use. Possible candidates are listed bellow:

Phase name                 |Condition
:--------------------------|-----------------------
phase_liquid               |
phase_gas                  |
phase_twophase             |
phase_supercritical        |
phase_supercritical_gas    |p < pc, T > Tc
phase_supercritical_liquid |p > pc, T < Tc
phase_critical_point       |p = pc, T = Tc
phase_unknown              |
phase_not_imposed          |

# Example
```julia
julia> heos = AbstractState_factory("HEOS", "Water");
# Do a flash call that is a very low density state point, definitely vapor
julia> @time AbstractState_update(heos, "DmolarT_INPUTS", 1e-6, 300);
  0.025233 seconds (5.23 k allocations: 142.283 KB)
# Specify the phase - for some inputs (especially density-temperature), this will result in a
# more direct evaluation of the equation of state without checking the saturation boundary
julia> AbstractState_specify_phase(heos, "phase_gas");
# We try it again - a bit faster
julia> @time AbstractState_update(heos, "DmolarT_INPUTS", 1e-6, 300);
  0.000050 seconds (5 allocations: 156 bytes)
julia> AbstractState_free(heos);
```
"""
function AbstractState_specify_phase(handle::Clong, phase::AbstractString)
    ccall( (:AbstractState_specify_phase, "CoolProp"), Void, (Clong, Cstring, Ref{Clong}, Ptr{UInt8}, Clong), handle, phase, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_unspecify_phase(handle::Clong)

Unspecify the phase to be used for all further calculations.

# Arguments
* `handle`: The integer handle for the state class stored in memory
"""
function AbstractState_unspecify_phase(handle::Clong)
    ccall( (:AbstractState_unspecify_phase, "CoolProp"), Void, (Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_update_and_common_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, hmolar::Array{Float64}, smolar::Array{Float64})
    AbstractState_update_and_common_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, hmolar::Array{Float64}, smolar::Array{Float64})

Update the state of the AbstractState and get an output value five common outputs (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `input_pair::Clong`: The integer value for the input pair obtained from get_input_pair_index
* `input_pair::AbstractString`:
* `value1`: The pointer to the array of the first input parameters
* `value2`: The pointer to the array of the second input parameters
* `length`: The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
* `T`: The pointer to the array of temperature
* `p`: The pointer to the array of pressure
* `rhomolar`: Array of molar density
* `hmolar`: The array of molar enthalpy
* `smolar`: Trray of molar entropy

# Example
```julia
julia> handle = AbstractState_factory("HEOS", "Water&Ethanol");
julia> pq_inputs = get_input_pair_index("PQ_INPUTS");
julia> AbstractState_set_fractions(handle, [0.4, 0.6]);
julia> T = [0.0]; p = [0.0]; rhomolar = [0.0]; hmolar = [0.0]; smolar = [0.0];
julia> AbstractState_update_and_common_out(handle, pq_inputs, [101325.0], [0.0], 1, T, p, rhomolar, hmolar, smolar);
julia> AbstractState_free(handle);
```
"""
function AbstractState_update_and_common_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, hmolar::Array{Float64}, smolar::Array{Float64})
    ccall( (:AbstractState_update_and_common_out, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Clong, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Clong}, Ptr{UInt8}, Clong), handle, input_pair, value1, value2, length, T, p, rhomolar, hmolar, smolar, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return T, p, rhomolar, hmolar, smolar
end

function AbstractState_update_and_common_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, hmolar::Array{Float64}, smolar::Array{Float64})
    return AbstractState_update_and_common_out(handle, get_input_pair_index(input_pair), value1, value2, length, T, p, rhomolar, hmolar, smolar)
end

function AbstractState_update_and_common_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer)
    T, p, rhomolar, hmolar, smolar = [fill(NaN,length) for i=1:5]
    return AbstractState_update_and_common_out(handle, input_pair, value1, value2, length, T, p, rhomolar, hmolar, smolar)
end

function AbstractState_update_and_common_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer)
    return AbstractState_update_and_common_out(handle, get_input_pair_index(input_pair), value1, value2, length)
end

"""
    AbstractState_update_and_1_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::Clong, out::Array{Float64})
    AbstractState_update_and_1_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::AbstractString, out::Array{Float64})

Update the state of the AbstractState and get one output value (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `input_pair::Clong`: The integer value for the input pair obtained from get_input_pair_index
* `input_pair::AbstractString`:
* `value1`: The pointer to the array of the first input parameters
* `value2`: The pointer to the array of the second input parameters
* `length`: The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
* `output`: The indice for the output desired
* `out`: The array for output
"""
function AbstractState_update_and_1_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::Clong, out::Array{Float64})
    ccall( (:AbstractState_update_and_1_out, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Clong, Clong, Ref{Cdouble}, Ref{Clong}, Ptr{UInt8}, Clong), handle, input_pair, value1, value2, length, output, out, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return out
end

function AbstractState_update_and_1_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::AbstractString, out::Array{Float64})
    return AbstractState_update_and_1_out(handle, get_input_pair_index(input_pair), value1, value2, length, get_param_index(output), out)
end

function AbstractState_update_and_1_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::Clong)
    out = fill(NaN,length)
    return AbstractState_update_and_1_out(handle, input_pair, value1, value2, length, output, out)
end

function AbstractState_update_and_1_out(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, output::AbstractString)
    return AbstractState_update_and_1_out(handle, get_input_pair_index(input_pair), value1, value2, length, get_param_index(output))
end

"""
    AbstractState_update_and_5_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{Clong}, out1::Array{Float64}, out2::Array{Float64}, out3::Array{Float64}, out4::Array{Float64}, out5::Array{Float64})
    AbstractState_update_and_5_out{S<:AbstractString}(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{S}, out1::Array{Float64}, out2::Array{Float64}, out3::Array{Float64}, out4::Array{Float64}, out5::Array{Float64})

Update the state of the AbstractState and get an output value five common outputs (temperature, pressure, molar density, molar enthalpy and molar entropy) from the AbstractState using pointers as inputs and output to allow array computation.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `input_pair::Clong`: The integer value for the input pair obtained from get_input_pair_index
* `input_pair::AbstractString`:
* `value1`: The pointer to the array of the first input parameters
* `value2`: The pointer to the array of the second input parameters
* `length`: The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
* `outputs`: The 5-element vector of indices for the outputs desired
* `out1`: The array for the first output
* `out2`: The array for the second output
* `out3`: The array for the third output
* `out4`: The array for the fourth output
* `out5`: The array for the fifth output
"""
function AbstractState_update_and_5_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{Clong}, out1::Array{Float64}, out2::Array{Float64}, out3::Array{Float64}, out4::Array{Float64}, out5::Array{Float64})
    ccall( (:AbstractState_update_and_5_out, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Clong, Ref{Clong}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Clong}, Ptr{UInt8}, Clong), handle, input_pair, value1, value2, length, outputs, out1, out2, out3, out4, out5, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return out1, out2, out3, out4, out5
end

function AbstractState_update_and_5_out{S<:AbstractString}(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{S}, out1::Array{Float64}, out2::Array{Float64}, out3::Array{Float64}, out4::Array{Float64}, out5::Array{Float64})
    outputs_key = [get_param_index(outputs[k]) for k = 1:5]
    return AbstractState_update_and_5_out(handle, get_input_pair_index(input_pair), value1, value2, length, outputs_key, out1, out2, out3, out4, out5)
end

function AbstractState_update_and_5_out(handle::Clong, input_pair::Clong, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{Clong})
    out1, out2, out3, out4, out5 = [fill(NaN,length) for i=1:5]
    return AbstractState_update_and_5_out(handle, input_pair, value1, value2, length, outputs, out1, out2, out3, out4, out5)
end

function AbstractState_update_and_5_out{S<:AbstractString}(handle::Clong, input_pair::AbstractString, value1::Array{Float64}, value2::Array{Float64}, length::Integer, outputs::Array{S})
    outputs_key = [get_param_index(outputs[k]) for k = 1:5]
    return AbstractState_update_and_5_out(handle, get_input_pair_index(input_pair), value1, value2, length, outputs_key)
end

"""
    AbstractState_set_binary_interaction_double(handle::Clong, i::Int, j::Int, parameter::AbstractString, value::Float64)

Set binary interraction parrameter for diffrent mixtures model e.g.: "linear", "Lorentz-Berthelot"

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `i`: indice of the first fluid of the binary pair
* `j`: indice of the second fluid of the binary pair
* `parameter`: string wit the name of the parameter, e.g.: "betaT", "gammaT", "betaV", "gammaV"
* `value`: the value of the binary interaction parameter

# Example
```julia
julia> handle = AbstractState_factory("HEOS", "Water&Ethanol");
julia> AbstractState_set_binary_interaction_double(handle, 0, 1, "betaT", 0.987);
julia> pq_inputs = get_input_pair_index("PQ_INPUTS");
julia> t = get_param_index("T");
julia> AbstractState_set_fractions(handle, [0.4, 0.6]);
julia> AbstractState_update(handle, pq_inputs, 101325, 0);
julia> AbstractState_keyed_output(handle, t)
349.32634425309755
julia> AbstractState_free(handle);
```
"""
function AbstractState_set_binary_interaction_double(handle::Clong, i::Integer, j::Integer, parameter::AbstractString, value::Real)
    ccall( (:AbstractState_set_binary_interaction_double, "CoolProp"), Void, (Clong, Clong, Clong, Cstring, Cdouble, Ref{Clong}, Ptr{UInt8}, Clong), handle, i, j, parameter, value, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_set_cubic_alpha_C(handle::Clong, i::Integer, parameter::AbstractString, c1::Real, c2::Real, c3::Real)

Set cubic's alpha function parameters.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `i`: indice of the fluid the parramter should be applied too (for mixtures)
* `parameter`: the string specifying the alpha function to use, e.g. "TWU" for the Twu or "MC" for Mathias-Copeman alpha function.
* `c1`: the first parameter for the alpha function
* `c2`: the second parameter for the alpha function
* `c3`: the third parameter for the alpha function
"""
function AbstractState_set_cubic_alpha_C(handle::Clong, i::Integer, parameter::AbstractString, c1::Real, c2::Real, c3::Real)
    ccall( (:AbstractState_set_cubic_alpha_C, "CoolProp"), Void, (Clong, Clong, Cstring, Cdouble, Cdouble, Cdouble, Ref{Clong}, Ptr{UInt8}, Clong), handle, i, parameter, c1, c2, c3, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_set_fluid_parameter_double(handle::Clong, i::Integer, parameter::AbstractString, value::Real)

Set some fluid parameter (ie volume translation for cubic). Currently applied to the whole fluid not to components.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `i`: indice of the fluid the parramter should be applied to (for mixtures)
* `parameter`: string wit the name of the parameter, e.g. "c", "cm", "c_m" for volume translation parrameter.
* `value`: the value of the parameter
"""
function AbstractState_set_fluid_parameter_double(handle::Clong, i::Integer, parameter::AbstractString, value::Real)
    ccall( (:AbstractState_set_fluid_parameter_double, "CoolProp"), Void, (Clong, Clong, Cstring, Cdouble, Ref{Clong}, Ptr{UInt8}, Clong), handle, i, parameter, value, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_first_saturation_deriv(handle::Clong, of::Clong, wrt::Clong)

Calculate a saturation derivative from the AbstractState using integer values for the desired parameters.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `of`: The parameter of which the derivative is being taken
* `wrt`: The derivative with with respect to this parameter

# Example
```julia
julia> as = AbstractState_factory("HEOS", "Water");
julia> AbstractState_update(as, "PQ_INPUTS", 15e5, 0);
julia> AbstractState_first_saturation_deriv(as, get_param_index("Hmolar"), get_param_index("P"))
0.0025636362140578207
```

# Ref
double CoolProp::AbstractState_first_saturation_deriv(const long handle, const long Of, const long Wrt, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_first_saturation_deriv(handle::Clong, of::Clong, wrt::Clong)
    output = ccall( (:AbstractState_first_saturation_deriv, "CoolProp"), Cdouble, (Clong, Clong, Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, of, wrt, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    if output == -Inf
        error("CoolProp: no correct state has been set with AbstractState_update")
    end
    return output
end

"""
    AbstractState_first_partial_deriv(handle::Clong, of::Clong, wrt::Clong, constant::Clong)

Calculate the first partial derivative in homogeneous phases from the AbstractState using integer values for the desired parameters.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `of`: The parameter of which the derivative is being taken
* `Wrt`: The derivative with with respect to this parameter
* `Constant`: The parameter that is not affected by the derivative

# Example
```julia
julia> as = AbstractState_factory("HEOS", "Water");
julia> AbstractState_update(as, "PQ_INPUTS", 15e5, 0);
julia> AbstractState_first_partial_deriv(as, get_param_index("Hmolar"), get_param_index("P"), get_param_index("S"))
2.07872526058326e-5
julia> AbstractState_first_partial_deriv(as, get_param_index("Hmolar"), get_param_index("P"), get_param_index("D"))
5.900781297636475e-5
```

# Ref
double CoolProp::AbstractState_first_partial_deriv(const long handle, const long Of, const long Wrt, const long Constant, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_first_partial_deriv(handle::Clong, of::Clong, wrt::Clong, constant::Clong)
    output = ccall( (:AbstractState_first_partial_deriv, "CoolProp"), Cdouble, (Clong, Clong, Clong, Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, of, wrt, constant, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    if output == -Inf
        error("CoolProp: no correct state has been set with AbstractState_update")
    end
    return output
end

"""
    AbstractState_build_phase_envelope(handle::Clong, level::AbstractString)

Build the phase envelope.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `level`: How much refining of the phase envelope ("none" to skip refining (recommended) or "veryfine")

# Note
If there is an error in an update call for one of the inputs, no change in the output array will be made

# Ref
CoolPRop::AbstractState_build_phase_envelope(const long handle, const char* level, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_build_phase_envelope(handle::Clong, level::AbstractString)
    ccall( (:AbstractState_build_phase_envelope, "CoolProp"), Void, (Clong, Cstring, Ref{Clong}, Ptr{UInt8}, Clong), handle, level, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_get_phase_envelope_data(handle::Clong, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar_vap::Array{Float64}, rhomolar_liq::Array{Float64}, x::Array{Float64}, y::Array{Float64})

Get data from the phase envelope for the given mixture composition.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `length`: The number of elements stored in the arrays (both inputs and outputs MUST be the same length)
* `T`: The pointer to the array of temperature (K)
* `p`: The pointer to the array of pressure (Pa)
* `rhomolar_vap`: The pointer to the array of molar density for vapor phase (m^3/mol)
* `rhomolar_liq`: The pointer to the array of molar density for liquid phase (m^3/mol)
* `x`: The compositions of the "liquid" phase (WARNING: buffer should be Ncomp*Npoints in length, at a minimum, but there is no way to check buffer length at runtime)
* `y`: The compositions of the "vapor" phase (WARNING: buffer should be Ncomp*Npoints in length, at a minimum, but there is no way to check buffer length at runtime)

# Example
```julia
julia> HEOS=AbstractState_factory("HEOS","Methane&Ethane");
julia> length=200;
julia> t=zeros(length);p=zeros(length);x=zeros(2*length);y=zeros(2*length);rhomolar_vap=zeros(length);rhomolar_liq=zeros(length);
julia> AbstractState_set_fractions(HEOS, [0.2, 1 - 0.2])
julia> AbstractState_build_phase_envelope(HEOS, "none")
julia> AbstractState_get_phase_envelope_data(HEOS, length, t, p, rhomolar_vap, rhomolar_liq, x, y)
julia> AbstractState_free(HEOS)
```

# Note
If there is an error in an update call for one of the inputs, no change in the output array will be made

# Ref
CoolProp::AbstractState_get_phase_envelope_data(const long handle, const long length, double* T, double* p, double* rhomolar_vap, double* rhomolar_liq, double* x, double* y, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_get_phase_envelope_data(handle::Clong, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar_vap::Array{Float64}, rhomolar_liq::Array{Float64}, x::Array{Float64}, y::Array{Float64})
    ccall( (:AbstractState_get_phase_envelope_data, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Clong}, Ptr{UInt8}, Clong), handle, length, T, p, rhomolar_vap, rhomolar_liq, x, y, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return T, p, rhomolar_vap, rhomolar_liq, x, y
end

function AbstractState_get_phase_envelope_data(handle::Clong, length::Integer, ncomp::Integer)
    T, p, rhomolar_vap, rhomolar_liq = [fill(NaN,length) for i=1:5]
    x, y = [fill(NaN,length*ncomp) for i=1:2]
    return AbstractState_get_phase_envelope_data(handle, length, T, p, rhomolar_vap, rhomolar_liq, x, y)
end

"""
    AbstractState_build_spinodal(handle::Clong)

Build the spinodal.

# Arguments
* `handle`: The integer handle for the state class stored in memory

# Ref
CoolProp::AbstractState_build_spinodal(const long handle, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_build_spinodal(handle::Clong)
    ccall( (:AbstractState_build_spinodal, "CoolProp"), Void, (Clong, Ref{Clong}, Ptr{UInt8}, Clong), handle, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return nothing
end

"""
    AbstractState_get_spinodal_data(handle::Clong, length::Integer, tau::Array{Float64}, dalta::Array{Float64}, m1::Array{Float64})

Get data for the spinodal curve.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `length`: The number of elements stored in the arrays (all outputs MUST be the same length)
* `tau`: The pointer to the array of reciprocal reduced temperature
* `delta`: The pointer to the array of reduced density
* `m1`: The pointer to the array of M1 values (when L1=M1=0, critical point)

# Note
If there is an error, no change in the output arrays will be made

# Example
julia> HEOS=AbstractState_factory("HEOS","Methane&Ethane");
julia> AbstractState_set_fractions(HEOS, [0.1, 0.9]);
julia> AbstractState_build_spinodal(HEOS);
julia> tau, delta, m1 = AbstractState_get_spinodal_data(HEOS, 127);

# Ref
CoolProp::AbstractState_get_spinodal_data(const long handle, const long length, double* tau, double* delta, double* M1, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_get_spinodal_data(handle::Clong, length::Integer, tau::Array{Float64}, delta::Array{Float64}, m1::Array{Float64})
    ccall( (:AbstractState_get_spinodal_data, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Clong}, Ptr{UInt8}, Clong), handle, length, tau, delta, m1, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return tau, delta, m1;
end

function AbstractState_get_spinodal_data(handle::Clong, length::Integer)
    tau, delta, m1 = [fill(NaN,length) for i=1:3]
    return AbstractState_get_spinodal_data(handle, length, tau, delta, m1)
end

"""
    abstractState_all_critical_points(handle::Clong, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, stable::Array{Clong})

Calculate all the critical points for a given composition.

# Arguments
* `handle`: The integer handle for the state class stored in memory
* `length`: The length of the buffers passed to this function
* `T`: The pointer to the array of temperature (K)
* `p`: The pointer to the array of pressure (Pa)
* `rhomolar`: The pointer to the array of molar density (m^3/mol)
* `stable`: The pointer to the array of boolean flags for whether the critical point is stable (1) or unstable (0)

# Note
If there is an error in an update call for one of the inputs, no change in the output array will be made

# Ref
CoolProp::AbstractState_all_critical_points(const long handle, const long length, double* T, double* p, double* rhomolar, long* stable, long* errcode, char* message_buffer, const long buffer_length);
"""
function AbstractState_all_critical_points(handle::Clong, length::Integer, T::Array{Float64}, p::Array{Float64}, rhomolar::Array{Float64}, stable::Array{Clong})
    ccall( (:AbstractState_all_critical_points, "CoolProp"), Void, (Clong, Clong, Ref{Cdouble}, Ref{Cdouble}, Ref{Cdouble}, Ref{Clong}, Ref{Clong}, Ptr{UInt8}, Clong), handle, length, T, p, rhomolar, stable, errcode, message_buffer::Array{UInt8, 1}, buffer_length)
    raise(errcode, message_buffer)
    return T, p, rhomolar, stable
end

function AbstractState_all_critical_points(handle::Clong, length::Integer)
    T, p, rhomolar = [fill(NaN,length) for i=1:3]
    stable = zeros(Clong, length)
    return  AbstractState_all_critical_points(handle, length, T, p, rhomolar, stable)
end
