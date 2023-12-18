You probably don't want to use this. I spent a few minutes writing the most naive possible fuzzer, to see if it would turn up any bugs. Turns out, this terrible method can generate bugs faster than I can debug them. However, the general approach and the specific implementation are pretty lame. If you're looking at this, you probably want something like [Csmith](https://github.com/csmith-project/csmith) or [jsfunfuzz](https://bugzilla.mozilla.org/show_bug.cgi?id=jsfunfuzz).

I'm planning to, eventually, write a real fuzzer to see if something that generates random expressions turns up more bugs than this. Suggestions / pull requests welcome.

### Confirmed/debugged bugs

[8353: parser loses track of location when `parse` is called](https://github.com/JuliaLang/julia/issues/8353)

[8352: underspecified type for writemime](https://github.com/JuliaLang/julia/pull/8352)

[8341: EOF mixed up in unicode hangs parser](https://github.com/JuliaLang/julia/issues/8341)

[8329: changing number of BLAS threads before operation causes segfault](https://github.com/JuliaLang/julia/issues/8329)

[8302: array sized incorrectly](https://github.com/JuliaLang/julia/pull/8302)

[8286: exponent of large number causes crashes with SIGABRT](https://github.com/JuliaLang/julia/issues/8286)

[8277: code near exception incorrectly optimized out](https://github.com/JuliaLang/julia/issues/8277)

[8266: hang/bad result on ndigits](https://github.com/JuliaLang/julia/pull/8266)

[8241: hang/segfault on long symbol](https://github.com/JuliaLang/julia/pull/8241)

[8239: segfault on code_native/code_llvm](https://github.com/JuliaLang/julia/pull/8239)

### TODO: debug these bugs

`searchindex` returns an unclear error message: 
~~~
julia> searchindex("q8NWiRVEW3NRTGXW6At7qN5aU2dhJ0ZGHSMfcH50k1Xsn1HIiPNRO0NXVhafnLkEd55","wKPx3QydhlLKz3fZQK3fCVhl6ZwMoFDq18ti1Ozcswi\
Av0Yq4k9utZgoN4KhdvIJiUjQcTIFZyD1cNmdsf1PcmmXMeh10N1",-234321342423423234534534543)
ERROR: error compiling searchindex: error compiling _searchindex: cannot convert type to a julia type
 in searchindex at string.jl:307
~~~

`sprandn` with bad args can take an arbitraily long time before erroring out.

`displayable` psuedo-randomly hangs.

`addprocs` of negative `Int128` causes something crazy to happen.

`replace` on string containing bad characters errors out instead of skipping past bad character. See `sandbox/3`.


### Odd non-bugs

[Special casing of some operators](https://groups.google.com/forum/#!topic/julia-users/ljQ-nHpXitU)

Address space randomiziation causes some methods to be randomized across invocations of julia.



