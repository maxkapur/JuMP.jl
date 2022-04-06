# [Nonlinear Modeling](@id NonlinearAPI)

More information can be found in the [Nonlinear](@ref nonlinear_developers)
section of the manual.

```@docs
Nonlinear.NonlinearData
```

## Expressions

```@docs
Nonlinear.add_expression
Nonlinear.ExpressionIndex
```

## Parameters

```@docs
Nonlinear.add_parameter
Nonlinear.ParameterIndex
```

## Objectives

```@docs
Nonlinear.set_objective
```

## Constraints

```@docs
Nonlinear.add_constraint
Nonlinear.ConstraintIndex
Nonlinear.delete
```

## User-defined operators

```@docs
Nonlinear.register_operator
```

## Automatic-differentiation backends

```@docs
Nonlinear.AutomaticDifferentiationBackend
Nonlinear.Default
Nonlinear.SparseReverseMode
Nonlinear.set_differentiation_backend
```
