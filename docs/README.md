# JuMP Documentation README

**The documentation currently requires Julia 1.6 to build.**

JuMP's documentation is written with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).

## Initial setup

To build the documentation, you need to do a series of initialization steps.
However, you only need to do this once!

First, you will need a local copy of JuMP. If you don't have one already, run:
```
$ julia -e 'import Pkg; Pkg.develop("JuMP")'
```

This will create a copy of JuMP at `~/.julia/dev/JuMP`. (On Windows, this will
be located at `C:\\Users\\<your_user_name>\\.julia\\dev\\JuMP`.) Open a terminal,
and `cd` to that directory:
```
$ cd ~/.julia/dev/JuMP
```

The next step is to setup the `docs` environment.
```
$ julia --project=docs -e 'import Pkg; Pkg.instantiate(); Pkg.develop(Pkg.PackageSpec(path="."))'
```

Now you're ready to build the documentation.

## Building the docs

Build the docs as follows:
```
$ cd ~/.julia/dev/JuMP
$ julia --project=docs docs/make.jl
```

The compiled documents can be viewed at `~/.julia/dev/JuMP/docs/build/index.html`.

## Updating Project.toml

Project.toml fixes the versions of JuMP-related packages such as MOI and the
solvers. This is to prevent minor changes in the upstream solvers (e.g.,
numerical differences or changes to their raw solver statuses) from causing the
documentation builds to fail on an un-related PR.

These versions should be periodically updated.
