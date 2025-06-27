using HokseonAssistant
using Distributed
using Test

@testset "HokseonAssistant.julia_session(Main process)" begin
    # Write your tests here.
    try
        HokseonAssistant.julia_session()
    catch e
        @error "HokseonAssistant.julia_session() failed" exception=e
        @test false  # Fail the test if initialization fails
    end
end


@testset "HokseonAssistant.julia_session(Multiple processes)" begin
    # Write your tests here.
    try
        addprocs(3)
        @everywhere using HokseonAssistant  # Ensure all workers can access HokseonAssistant
        HokseonAssistant.julia_session()
    catch e
        @error "HokseonAssistant.julia_session() failed" exception=e
        @test false  # Fail the test if initialization fails
    end
end
