

module JobInfoUtils # This defines the submodule JobInfoUtils

using Distributed # Submodules also need to explicitly `using` packages they depend on

export get_job_id, initialize_workers_with_job_info, initialize_num_threads # Export from the submodule

# Define the function
function get_job_id()
    try
        if haskey(ENV, "SLURM_JOB_ID")
            job_id = ENV["SLURM_JOB_ID"]
            id_source = "SLURM_JOB_ID"
        elseif haskey(ENV, "SESSION_ID")
            job_id = ENV["SESSION_ID"]
            id_source = "SESSION_ID"
        else
            job_id = "local_run"
            id_source = "DEFAULT"
        end

        parsed_id = tryparse(Int, job_id)
        id_value = isnothing(parsed_id) ? job_id : parsed_id
        return (id_value, id_source)

    catch e
        @error "Failed to get job ID" exception=e
        exit(1)
    end
end



function worker_info(job_id, id_source)
    println("Worker $(myid()) | Job ID: $job_id | Source: $id_source | Host: $(gethostname())")
end

# Function to initialize workers with job info
function initialize_workers_with_job_info()
    job_id, id_source = get_job_id()

    # Print from main process
    println("Main process Job ID: $job_id")

    # Check if we have workers
    if nworkers() > 0
        # Print from all workers
        # Call the worker_info defined within this submodule explicitly
        # It's crucial to qualify it as HokseonAssistant.JobInfoUtils.worker_info
        # when passing it to remotecall_fetch if it's not defined in Main.
        # However, because it's defined with `@everywhere` *inside* the submodule,
        # Julia should find HokseonAssistant.JobInfoUtils.worker_info on the workers.
        # But if you still encounter `UndefVarError`, explicitly qualify it here:
        # `pmap(worker -> remotecall_fetch(HokseonAssistant.JobInfoUtils.worker_info, worker, job_id, id_source), workers())`
        # For now, let's keep it simple and rely on @everywhere's magic within the submodule:
        pmap(worker -> remotecall_fetch(worker_info, worker, job_id, id_source), workers())
    else
        println("No workers available. Running on main process only.")
        println("Main process | Job ID: $job_id | Source: $id_source | Host: $(gethostname())")
    end

    return job_id, id_source
end


function initialize_num_threads()

    if haskey(ENV, "SLURM_CPUS_PER_TASK") && !isempty(ENV["SLURM_CPUS_PER_TASK"])
        # If SLURM is detected, use SLURM_CPUS_PER_TASK
        num_threads_val = parse(Int, ENV["SLURM_CPUS_PER_TASK"])
        println("Running on SLURM: Using $num_threads_val threads per task.")
    elseif haskey(ENV, "JULIA_NUM_THREADS") && !isempty(ENV["JULIA_NUM_THREADS"])
        # If not SLURM, use a fallback (e.g., use JULIA_NUM_THREADS or default to 1)
        num_threads_val = parse(Int, get(ENV, "JULIA_NUM_THREADS", 1))  # Default to "1" as a string, then parse to Int
        println("Running bash locally: Using $num_threads_val threads per worker.")
    else
        # Default to 1 thread if neither SLURM nor JULIA_NUM_THREADS is set
        # In this case, user is pressing the run button in the IDE
        num_threads_val = 1
        println("No SLURM or local bash detected: Defaulting to $num_threads_val thread.")
    end

    return num_threads_val

end




end # End of module JobInfoUtils
