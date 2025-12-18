module JobInfoUtils

using Distributed
using ClusterManagers: SlurmManager
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

    if nprocs() > 1
        # Workers RETURN strings; master prints
        msgs = [
            remotecall_fetch(w) do
                "   Worker $w | Job ID: $job_id | Source: $id_source | " *
                "   Host: $(gethostname()) | Thread(s): $(Threads.nthreads())"
            end
            for w in workers()
        ]


        foreach(println, sort(msgs))
    else
        println("No workers available. Running on main process only.")
        println(
            "   Main process | Job ID: $job_id | Source: $id_source | " *
            "   Host: $(gethostname()) | Thread(s): $(Threads.nthreads())"
        )
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

# Determine number of threads for main process
function initialize_procs(;add_nprocs::Int=0)

    old_workers = Set(workers())

    project = Base.active_project()

    if haskey(ENV, "SLURM_JOB_ID")
        # 1. SLURM CASE: Handle multi-node distribution
        nworker = parse(Int, ENV["SLURM_NTASKS"])
        num_threads_val = parse(Int, ENV["SLURM_CPUS_PER_TASK"])
        println("Running on SLURM: Launching $(nworker) workers across nodes. Using $num_threads_val threads per worker.")
        println("No additional workers will be added since SLURM manages worker allocation.")

        # Start workers with SlurmManager
        ENV["SLURM_SRUN_ARGS"] = "--output=/dev/null --error=/dev/null"
        
        if nworkers() != nworker
            addprocs(
                SlurmManager(nworker);
                exeflags=[
                    "--project=$project",
                    "-t $num_threads_val",
                ]
            )
        end

        add_nprocs = 0  ## Slurm prevent adding more procs from here
    elseif nprocs() > 1
        # 2. COMMAND LINE CASE: User ran 'julia -p 10 -t 2'
        nworker = nworkers()  # including main process
        num_threads_val = Threads.nthreads() 
        println("Running by -p flag: $(nworker) workers detected; each worker has $num_threads_val thread(s).")
    else
        # 3. LOCAL FALLBACK: Manual start (e.g., inside VS Code or REPL) or julia -t 4
        nworker = 0
        num_threads_val = Threads.nthreads()
        println("Running locally:  Defaulting to $num_threads_val thread(s) with a master worker.")
    end

    new_workers = setdiff(workers(), old_workers)

    if add_nprocs > 0 || new_workers != Set()
        # 4. ADD ADDITIONAL WORKERS IF REQUESTED in the programme

        if add_nprocs > 0
            before_add_nprocs = nprocs()
            if before_add_nprocs > 1
                rmprocs(workers())
            end
            total_workers = before_add_nprocs + add_nprocs - 1  # exclude main process
            num_threads_val = div(Sys.CPU_THREADS, total_workers)
            println("Adding $add_nprocs additional worker(s) by julia_build_procs():\nTotal workers will be: $total_workers\n Each worker will have $num_threads_val thread(s).")

            addprocs(total_workers; exeflags=[
                "--project=$project",
                "-t $num_threads_val"
            ])
        end

        new_workers = setdiff(workers(), old_workers)
        
        for w in new_workers
            Distributed.remotecall_eval(Main, w, :(using HokseonAssistant))
        end
    end

    return num_threads_val
end

end # module JobInfoUtils
