using AWSTools: timeout

@testset "timeout" begin
    timeout(() -> nothing, 0)

    @testset "finish" begin
        secs = @elapsed begin
            result = timeout(() -> 0, 1)
        end
        @test result == Some(0)
        @test secs < 1
    end

    @testset "abort" begin
        secs = @elapsed begin
            result = timeout(1) do
                sleep(5)
                error("unexpected error")
            end
        end
        @test result === nothing
        @test 1 <= secs < 5
    end

    @testset "return nothing" begin
        secs = @elapsed begin
            result = timeout(() -> nothing, 1)
        end
        @test result == Some(nothing)
        @test secs < 1
    end

    @testset "exception" begin
        local exception
        secs = @elapsed begin
            try
                timeout(() -> error("function error"), 5)
            catch e
                exception = e
            end
        end
        @test exception isa CompositeException
        @test length(exception.exceptions) == 1
        @test exception.exceptions[1] isa CapturedException
        @test exception.exceptions[1].ex == ErrorException("function error")
        @test secs < 5
    end
end
