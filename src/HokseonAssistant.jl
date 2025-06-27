# src/HokseonAssistant.jl

module HokseonAssistant

using Distributed 

include("jobinfo/JobInfoUtils.jl")

using .JobInfoUtils # This makes JobInfoUtils.get_job_id callable as get_job_id within HokseonAssistant

# export variables
export num_threads


num_threads::Int = 0

function julia_session(broadcast_num_threads::Bool = true)

    global num_threads

    JobInfoUtils.initialize_workers_with_job_info()
    num_threads = JobInfoUtils.initialize_num_threads()
    broadcast_num_threads && @everywhere num_threads = $num_threads;

end

end # End of module HokseonAssistant
