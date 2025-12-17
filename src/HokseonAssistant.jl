module HokseonAssistant

using Distributed
include("jobinfo/JobInfoUtils.jl")
using .JobInfoUtils

export num_threads, julia_session, julia_build_procs

# Thread count variable
num_threads::Int = 0

"""
    julia_session(broadcast_num_threads::Bool=true)

Initialize job info and thread counts.

- Only call this on the main process.
- Broadcasts `num_threads` to all workers if `broadcast_num_threads` is true.
"""
function julia_session(broadcast_num_threads::Bool = true)
    global num_threads

    # Initialize workers with job info
    job_id, id_source = JobInfoUtils.initialize_workers_with_job_info_main_only()

    # Initialize number of threads on main process
    num_threads = JobInfoUtils.initialize_num_threads()

    # Optionally broadcast to all workers (just a variable, not functions)
    if broadcast_num_threads && nworkers() > 0
        #@info "Broadcasting num_threads=$num_threads to all workers"
        @everywhere global num_threads = $num_threads
    end

    return job_id, id_source
end

function julia_build_procs(broadcast_num_threads::Bool = true;add_nprocs::Int=0)

    global num_threads
    println("Attention!! julia_build_procs() is not recommended doing julia -p x your_script.jl in slurm sbatch scripts.")

    # Initialize number of threads on main process
    num_threads = JobInfoUtils.initialize_procs(;add_nprocs)
    

    # Initialize workers with job info
    job_id, id_source = JobInfoUtils.initialize_workers_with_job_info_main_only()

    # Optionally broadcast to all workers (just a variable, not functions)
    if broadcast_num_threads && nworkers() > 0
        #@info "Broadcasting num_threads=$num_threads to all workers"
        @everywhere global num_threads = $num_threads
    end

    return job_id, id_source
end

end # module HokseonAssistant

