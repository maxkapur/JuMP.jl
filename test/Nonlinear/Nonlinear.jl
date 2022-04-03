module TestNonlinear

using Test
import JuMP: MOI
import JuMP: Nonlinear

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_parse_sin()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(sin($x)))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(sin(x[$x]))
    return
end

function test_parse_sin_squared()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(sin($x)^2))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(sin(x[$x])^2)
    return
end

function test_parse_ifelse()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(ifelse($x, 1, 2)))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(ifelse(x[$x], 1, 2))
    return
end

function test_parse_ifelse_inequality_less()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(ifelse($x < 1, $x - 1, $x + 1)))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(ifelse(x[$x] < 1, x[$x] - 1, x[$x] + 1))
    return
end

function test_parse_ifelse_inequality_greater()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(ifelse($x > 1, $x - 1, $x + 1)))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(ifelse(x[$x] > 1, x[$x] - 1, x[$x] + 1))
    return
end

function test_parse_ifelse_comparison()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    Nonlinear.set_objective(data, :(ifelse(0 <= $x <= 1, $x - 1, $x + 1)))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) ==
          :(ifelse(0 <= x[$x] <= 1, x[$x] - 1, x[$x] + 1))
    return
end

function test_parse_ifelse_logic_inequality()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    expr = :(ifelse($x < 1.0 || $x > 2.0, $x - 1.0, $x + 1.0))
    Nonlinear.set_objective(data, expr)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) ==
          :(ifelse(x[$x] < 1.0 || x[$x] > 2.0, x[$x] - 1.0, x[$x] + 1.0))
    return
end

function test_moi_variable_parse()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    expr = Nonlinear.parse_expression(data, :($x))
    @test expr.nodes == [Nonlinear.Node(Nonlinear.NODE_MOI_VARIABLE, 1, -1)]
    @test isempty(expr.values)
    return
end

function test_expression_parse()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    ex = Nonlinear.add_expression(data, :(sin($x)^2))
    @test data[ex] isa Nonlinear.NonlinearExpression
    return
end

function test_parameter_parse()
    data = Nonlinear.NonlinearData()
    p = Nonlinear.add_parameter(data, 1.2)
    expr = Nonlinear.parse_expression(data, :($p))
    @test expr.nodes == [Nonlinear.Node(Nonlinear.NODE_PARAMETER, 1, -1)]
    @test isempty(expr.values)
    @test data.parameters == [1.2]
    return
end

function test_parameter_set()
    data = Nonlinear.NonlinearData()
    p = Nonlinear.add_parameter(data, 1.2)
    @test data.parameters == [1.2]
    @test data[p] == 1.2
    Nonlinear.set_parameter(data, p, 2.1)
    @test data.parameters == [2.1]
    @test data[p] == 2.1
    return
end

function test_set_objective()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1)
    Nonlinear.set_objective(data, input)
    @test data.objective == Nonlinear.parse_expression(data, input)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(x[$x]^2 + 1)
    return
end

function test_set_objective_subexpression()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1)
    expr = Nonlinear.add_expression(data, input)
    Nonlinear.set_objective(data, :($expr^2))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :((x[$x]^2 + 1)^2)
    return
end

function test_set_objective_nested_subexpression()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1)
    expr = Nonlinear.add_expression(data, input)
    expr_2 = Nonlinear.add_expression(data, :($expr^2))
    Nonlinear.set_objective(data, :($expr_2^2))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(((x[$x]^2 + 1)^2)^2)
    return
end

function test_set_objective_parameter()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    p = Nonlinear.add_parameter(data, 1.2)
    Nonlinear.set_objective(data, :($x^2 + $p))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.objective_expr(data) == :(x[$x]^2 + 1.2)
    return
end

function test_add_constraint_less_than()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1 <= 1.0)
    c = Nonlinear.add_constraint(data, input)
    @test data[c].set == MOI.LessThan(0.0)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :((x[$x]^2 + 1) - 1.0 <= 0.0)
    return
end

function test_add_constraint_delete()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    c1 = Nonlinear.add_constraint(data, :($x^2 + 1 <= 1.0))
    _ = Nonlinear.add_constraint(data, :(sqrt($x) <= 1.0))
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :((x[$x]^2 + 1) - 1.0 <= 0.0)
    @test MOI.constraint_expr(data, 2) == :((sqrt(x[$x])) - 1.0 <= 0.0)
    Nonlinear.delete(data, c1)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :(sqrt(x[$x]) - 1.0 <= 0.0)
    @test_throws BoundsError MOI.constraint_expr(data, 2)
    return
end

function test_add_constraint_less_than_normalize()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :(1 <= 1.0 + $x^2)
    c = Nonlinear.add_constraint(data, input)
    @test data[c].set == MOI.LessThan(0.0)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :(1 - (1.0 + x[$x]^2) - 0.0 <= 0.0)
    return
end

function test_add_constraint_greater_than()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1 >= 1.0)
    c = Nonlinear.add_constraint(data, input)
    @test data[c].set == MOI.GreaterThan(0.0)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :((x[$x]^2 + 1) - 1.0 >= 0.0)
    return
end

function test_add_constraint_equal_to()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :($x^2 + 1 == 1.0)
    c = Nonlinear.add_constraint(data, input)
    @test data[c].set == MOI.EqualTo(0.0)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :((x[$x]^2 + 1) - 1.0 == 0.0)
    return
end

function test_add_constraint_interval()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :(-1.0 <= $x^2 + 1 <= 1.0)
    c = Nonlinear.add_constraint(data, input)
    @test data[c].set == MOI.Interval(-1.0, 1.0)
    MOI.initialize(data, [:ExprGraph])
    @test MOI.constraint_expr(data, 1) == :(-1.0 <= x[$x]^2 + 1 <= 1.0)
    return
end

function test_add_constraint_interval_normalize()
    data = Nonlinear.NonlinearData()
    x = MOI.VariableIndex(1)
    input = :(-1.0 + $x <= $x^2 + 1 <= 1.0)
    @test_throws(ErrorException, Nonlinear.add_constraint(data, input))
    return
end

function test_eval_univariate_function()
    r = Nonlinear.OperatorRegistry()
    @test Nonlinear.eval_univariate_function(r, :+, 1.0) == 1.0
    @test Nonlinear.eval_univariate_function(r, :-, 1.0) == -1.0
    @test Nonlinear.eval_univariate_function(r, :abs, -1.1) == 1.1
    @test Nonlinear.eval_univariate_function(r, :abs, 1.1) == 1.1
    return
end

function test_eval_univariate_gradient()
    r = Nonlinear.OperatorRegistry()
    @test Nonlinear.eval_univariate_gradient(r, :+, 1.2) == 1.0
    @test Nonlinear.eval_univariate_gradient(r, :-, 1.2) == -1.0
    @test Nonlinear.eval_univariate_gradient(r, :abs, -1.1) == -1.0
    @test Nonlinear.eval_univariate_gradient(r, :abs, 1.1) == 1.0
    return
end

function test_eval_univariate_hessian()
    r = Nonlinear.OperatorRegistry()
    @test Nonlinear.eval_univariate_hessian(r, :+, 1.2) == 0.0
    @test Nonlinear.eval_univariate_hessian(r, :-, 1.2) == 0.0
    @test Nonlinear.eval_univariate_hessian(r, :abs, -1.1) == 0.0
    @test Nonlinear.eval_univariate_hessian(r, :abs, 1.1) == 0.0
    return
end

function test_eval_univariate_function_registered()
    r = Nonlinear.OperatorRegistry()
    f(x) = sin(x)^2
    grad_calls = 0
    f′(x) = (grad_calls += 1; 2 * sin(x) * cos(x))
    hess_calls = 0
    f′′(x) = (hess_calls += 1; 2 * (cos(x)^2 - sin(x)^2))
    Nonlinear.register_operator(r, :f, 1, f)
    x = 1.2
    @test Nonlinear.eval_univariate_function(r, :f, x) ≈ f(x)
    @test Nonlinear.eval_univariate_gradient(r, :f, x) ≈ f′(x)
    @test grad_calls == 1
    @test Nonlinear.eval_univariate_hessian(r, :f, x) ≈ f′′(x)
    @test hess_calls == 1
    return
end

function test_eval_univariate_function_registered_grad()
    r = Nonlinear.OperatorRegistry()
    f(x) = sin(x)^2
    grad_calls = 0
    f′(x) = (grad_calls += 1; 2 * sin(x) * cos(x))
    hess_calls = 0
    f′′(x) = (hess_calls += 1; 2 * (cos(x)^2 - sin(x)^2))
    Nonlinear.register_operator(r, :f, 1, f, f′)
    @test grad_calls == 2
    x = 1.2
    @test Nonlinear.eval_univariate_function(r, :f, x) ≈ f(x)
    @test Nonlinear.eval_univariate_gradient(r, :f, x) ≈ f′(x)
    @test grad_calls == 4
    @test Nonlinear.eval_univariate_hessian(r, :f, x) ≈ f′′(x)
    @test hess_calls == 1
    return
end

function test_eval_univariate_function_registered_grad_hess()
    r = Nonlinear.OperatorRegistry()
    f(x) = sin(x)^2
    grad_calls = 0
    f′(x) = (grad_calls += 1; 2 * sin(x) * cos(x))
    hess_calls = 0
    f′′(x) = (hess_calls += 1; 2 * (cos(x)^2 - sin(x)^2))
    Nonlinear.register_operator(r, :f, 1, f, f′, f′′)
    x = 1.2
    @test Nonlinear.eval_univariate_function(r, :f, x) ≈ f(x)
    @test Nonlinear.eval_univariate_gradient(r, :f, x) ≈ f′(x)
    @test grad_calls == 2
    @test Nonlinear.eval_univariate_hessian(r, :f, x) ≈ f′′(x)
    @test hess_calls == 2
    return
end

function test_eval_multivariate_function()
    r = Nonlinear.OperatorRegistry()
    x = [1.1, 2.2]
    @test Nonlinear.eval_multivariate_function(r, :+, x) ≈ 3.3
    @test Nonlinear.eval_multivariate_function(r, :-, x) ≈ -1.1
    @test Nonlinear.eval_multivariate_function(r, :*, x) ≈ 1.1 * 2.2
    @test Nonlinear.eval_multivariate_function(r, :^, x) ≈ 1.1^2.2
    @test Nonlinear.eval_multivariate_function(r, :/, x) ≈ 1.1 / 2.2
    @test Nonlinear.eval_multivariate_function(r, :ifelse, [1; x]) == 1.1
    @test Nonlinear.eval_multivariate_function(r, :ifelse, [0; x]) == 2.2
    return
end

function test_eval_multivariate_gradient()
    r = Nonlinear.OperatorRegistry()
    x = [1.1, 2.2]
    g = zeros(2)
    Nonlinear.eval_multivariate_gradient(r, :+, g, x)
    @test g == [1.0, 1.0]
    Nonlinear.eval_multivariate_gradient(r, :-, g, x)
    @test g == [1.0, -1.0]
    Nonlinear.eval_multivariate_gradient(r, :*, g, x)
    @test g ≈ [2.2, 1.1]
    Nonlinear.eval_multivariate_gradient(r, :^, g, x)
    @test g ≈ [2.2 * 1.1^1.2, 1.1^2.2 * log(1.1)]
    Nonlinear.eval_multivariate_gradient(r, :/, g, x)
    @test g ≈ [1 / 2.2, -1.1 / 2.2^2]
    g = zeros(3)
    Nonlinear.eval_multivariate_gradient(r, :ifelse, g, [1; x])
    @test g ≈ [0.0, 1.0, 0.0]
    Nonlinear.eval_multivariate_gradient(r, :ifelse, g, [0; x])
    @test g ≈ [0.0, 0.0, 1.0]
    return
end

function test_eval_multivariate_gradient_mult()
    r = Nonlinear.OperatorRegistry()
    x = [1.1, 0.0, 2.2]
    g = zeros(3)
    Nonlinear.eval_multivariate_gradient(r, :*, g, x)
    @test g == [0.0, 1.1 * 2.2, 0.0]
    return
end

function test_eval_multivariate_hessian()
    r = Nonlinear.OperatorRegistry()
    x = [1.1, 2.2]
    H = zeros(2, 2)
    # TODO(odow): implement
    @test_throws(
        ErrorException,
        Nonlinear.eval_multivariate_hessian(r, :+, H, x),
    )
    return
end

function test_eval_multivariate_function_registered()
    r = Nonlinear.OperatorRegistry()
    f(x...) = x[1]^2 + x[1] * x[2] + x[2]^2
    Nonlinear.register_operator(r, :f, 2, f)
    x = [1.1, 2.2]
    @test Nonlinear.eval_multivariate_function(r, :f, x) ≈ f(x...)
    g = zeros(2)
    Nonlinear.eval_multivariate_gradient(r, :f, g, x)
    @test g ≈ [2 * x[1] + x[2], x[1] + 2 * x[2]]
    H = zeros(2, 2)
    @test_throws(
        ErrorException,
        Nonlinear.eval_multivariate_hessian(r, :f, H, x),
    )
    return
end

function test_eval_multivariate_function_registered_grad()
    r = Nonlinear.OperatorRegistry()
    f(x...) = x[1]^2 + x[1] * x[2] + x[2]^2
    grad_calls = 0
    function ∇f(g, x...)
        grad_calls += 1
        g[1] = 2 * x[1] + x[2]
        g[2] = x[1] + 2 * x[2]
        return
    end
    Nonlinear.register_operator(r, :f, 2, f, ∇f)
    x = [1.1, 2.2]
    @test Nonlinear.eval_multivariate_function(r, :f, x) ≈ f(x...)
    g = zeros(2)
    Nonlinear.eval_multivariate_gradient(r, :f, g, x)
    @test g ≈ [2 * x[1] + x[2], x[1] + 2 * x[2]]
    @test grad_calls == 1
    H = zeros(2, 2)
    @test_throws(
        ErrorException,
        Nonlinear.eval_multivariate_hessian(r, :f, H, x),
    )
    return
end

function test_eval_logic_function()
    for lhs in (true, false), rhs in (true, false)
        @test Nonlinear.eval_logic_function(:&&, lhs, rhs) == (lhs && rhs)
        @test Nonlinear.eval_logic_function(:||, lhs, rhs) == (lhs || rhs)
        @test_throws(
            AssertionError,
            Nonlinear.eval_logic_function(:⊻, lhs, rhs),
        )
    end
    return
end

function test_eval_comprison_function()
    for lhs in (true, false), rhs in (true, false)
        @test Nonlinear.eval_comparison_function(:<=, lhs, rhs) == (lhs <= rhs)
        @test Nonlinear.eval_comparison_function(:>=, lhs, rhs) == (lhs >= rhs)
        @test Nonlinear.eval_comparison_function(:(==), lhs, rhs) ==
              (lhs == rhs)
        @test Nonlinear.eval_comparison_function(:<, lhs, rhs) == (lhs < rhs)
        @test Nonlinear.eval_comparison_function(:>, lhs, rhs) == (lhs > rhs)
        @test_throws(
            AssertionError,
            Nonlinear.eval_comparison_function(:⊻, lhs, rhs),
        )
    end
    return
end

function test_features_available()
    data = Nonlinear.NonlinearData()
    @test MOI.features_available(data) == [:ExprGraph]
    return
end

end

TestNonlinear.runtests()
