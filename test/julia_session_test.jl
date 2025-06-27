using Distributed
addprocs(3)

using HokseonAssistant # This line is crucial!

HokseonAssistant.julia_session();

@everywhere @info "Worker $(myid()) has num_threads = $num_threads"