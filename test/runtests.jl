using HokseonAssistant
using Distributed
using Test


@info "The correct number of threads in the main process : $(Threads.nthreads())" 
@info "HokseonAssistant path" pathof(HokseonAssistant)


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

@testset "HokseonAssistant.julia_build_procs(Main process)" begin
    # Write your tests here.
    try
        HokseonAssistant.julia_build_procs()
    catch e
        @error "HokseonAssistant.julia_build_procs() failed" exception=e
        @test false  # Fail the test if initialization fails
    end
end

@testset "HokseonAssistant.julia_build_procs(Multiple processes)" begin
    # Write your tests here.
    try
        addprocs(2)
        @everywhere using HokseonAssistant  # Ensure all workers can access HokseonAssistant
        HokseonAssistant.julia_build_procs()
    catch e
        @error "HokseonAssistant.julia_build_procs() failed" exception=e
        @test false  # Fail the test if initialization fails
    end
end
