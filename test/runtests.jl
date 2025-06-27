using HokseonAssistant
using Distributed
using Test

# Ensure the current environment path is known
env_path = Base.active_project()
@info "Active project: $env_path"

@testset "HokseonAssistant.julia_session(Main process)" begin
    try
        HokseonAssistant.julia_session()
    catch e
        @error "HokseonAssistant.julia_session() failed" exception=e
        @test false
    end
end

@testset "HokseonAssistant.julia_session(Multiple processes)" begin
    try
        addprocs(3)

        @everywhere begin
            # Load the same environment as the main process
            import Pkg
            Pkg.activate("$(dirname(Base.active_project()))")
            Pkg.instantiate()
            using HokseonAssistant
        end

        HokseonAssistant.julia_session()
    catch e
        @error "HokseonAssistant.julia_session() failed" exception=e
        @test false
    end
end
