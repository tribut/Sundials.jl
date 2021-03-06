##################################################################
#
# Pointers to Sundials objects
#
##################################################################

"""
    Base type for dummy placeholders that help to
    providing typed pointers for Sundials objects
    (KINSOL, CVODE, IDA).

    See `Handle`.
"""
@compat abstract type AbstractSundialsObject end

immutable CVODEMem <: AbstractSundialsObject end
const CVODEMemPtr = Ptr{CVODEMem}

immutable IDAMem <: AbstractSundialsObject end
const IDAMemPtr = Ptr{IDAMem}

immutable KINMem <: AbstractSundialsObject end
const KINMemPtr = Ptr{KINMem}

"""
   Handle for Sundials objects (CVODE, IDA, KIN).

   Wraps the reference to the pointer to the Sundials object.
   Manages automatic destruction of the referenced objects when it is
   no longer in use.
"""
immutable Handle{T <: AbstractSundialsObject}
    ptr_ref::Ref{Ptr{T}} # pointer to a pointer

    @compat function (::Type{Handle}){T <: AbstractSundialsObject}(ptr::Ptr{T})
        h = new{T}(Ref{Ptr{T}}(ptr))
        finalizer(h.ptr_ref, release_handle)
        return h
    end
end

Base.convert{T}(::Type{Ptr{T}}, h::Handle{T}) = h.ptr_ref[]
Base.convert{T}(::Type{Ptr{Ptr{T}}}, h::Handle{T}) = convert(Ptr{Ptr{T}}, h.ptr_ref[])

release_handle{T}(ptr_ref::Ref{Ptr{T}}) = throw(MethodError("Freeing objects of type $T not supported"))
release_handle(ptr_ref::Ref{Ptr{KINMem}}) = (ptr_ref[] != C_NULL) && KINFree(ptr_ref)
release_handle(ptr_ref::Ref{Ptr{CVODEMem}}) = (ptr_ref[] != C_NULL) && CVodeFree(ptr_ref)
release_handle(ptr_ref::Ref{Ptr{IDAMem}}) = (ptr_ref[] != C_NULL) && IDAFree(ptr_ref)

Base.empty!{T}(h::Handle{T}) = release_handle(h.ptr_ref)
Base.isempty{T}(h::Handle{T}) = h.ptr_ref[] == C_NULL

##################################################################
#
# Convenience typealiases for Sundials handles
#
##################################################################

const CVODEh = Handle{CVODEMem}
const KINh =  Handle{KINMem}
const IDAh =  Handle{IDAMem}
