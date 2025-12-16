module JobInfoUtils

using Distributed

export get_job_id, initialize_workers_with_job_info_main_only, initialize_num_threads

# Get job ID (SLURM, SESSION_ID, or default)
function get_job_id()
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
end

# Worker info print
function worker_info_main_only(worker::Int, job_id, id_source)
    println("Worker $worker | Job ID: $job_id | Source: $id_source | Host: $(gethostname()) | Thread(s): $(Threads.nthreads())")
end

# Initialize workers: only call remotecall from main, do not require HokseonAssistant on workers
function initialize_workers_with_job_info_main_only()
    job_id, id_source = get_job_id()

    println("Main process Job ID: $job_id")

    if nworkers() > 0
        # Call worker_info on each worker using anonymous function
        pmap(w -> remotecall_fetch(() -> println("Worker $w | Job ID: $job_id | Source: $id_source | Host: $(gethostname()) | Thread(s): $(Threads.nthreads())"), w), workers())
    else
        println("No workers available. Running on main process only.")
        println("Main process | Job ID: $job_id | Source: $id_source | Host: $(gethostname()) | Thread(s): $(Threads.nthreads())")
    end

    return job_id, id_source
end

# Determine number of threads for main process
function initialize_num_threads()
    if haskey(ENV, "SLURM_CPUS_PER_TASK") && !isempty(ENV["SLURM_CPUS_PER_TASK"])
        num_threads_val = parse(Int, ENV["SLURM_CPUS_PER_TASK"])
        println("Running on SLURM: Using $num_threads_val threads per task.")
    elseif haskey(ENV, "JULIA_NUM_THREADS") && !isempty(ENV["JULIA_NUM_THREADS"])
        num_threads_val = parse(Int, get(ENV, "JULIA_NUM_THREADS", "1"))
        println("Running locally: Using $num_threads_val threads per worker.")
    else
        num_threads_val = Threads.nthreads()
        println("Defaulting to $num_threads_val thread(s).")
    end
    return num_threads_val
end

end # module JobInfoUtils
