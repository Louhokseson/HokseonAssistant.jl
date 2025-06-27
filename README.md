# HokseonAssistant

[![Build Status](https://github.com/Louhokseson/HokseonAssistant.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Louhokseson/HokseonAssistant.jl/actions/workflows/CI.yml?query=branch%3Amain)


#### A few words from the author
This Julia package is designed to facilitate the author Hokseon's need in his julia coding journey. Feel free to use it and contribute to it. And this package acts a easy playground for building julia packages. If you have any questions, please don't bother me, just ask [deepseek](https://www.deepseek.com).


## Key features
#### JobInfoUtils
 A utility module for managing job information in distributed Julia environments.
1. **julia_session**: A function to print job information and initialize the number of threads for each worker by `num_threads`.
###### Examples
In the **julia main process**, you can call `julia_session()` to initialize the job information.
```julia
using Distributed
using HokseonAssistant 
HokseonAssistant.julia_session()
@everywhere @info "Worker $(myid()) has num_threads = $num_threads"

Main process Job ID: local_run
Worker 1 | Job ID: local_run | Source: DEFAULT | Host: your_host_name
No SLURM or local bash detected: Defaulting to 1 thread.
[ Info: Worker 1 has num_threads = 1
```
For distributed computing, `julia_session()` works in this way:
```julia
using Distributed
addprocs(3)
using HokseonAssistant 
HokseonAssistant.julia_session();
@everywhere @info "Worker $(myid()) has num_threads = $num_threads"

Main process Job ID: local_run
      From worker 2:    Worker 2 | Job ID: local_run | Source: DEFAULT | Host: your_host_name
      From worker 4:    Worker 4 | Job ID: local_run | Source: DEFAULT | Host: your_host_name
      From worker 3:    Worker 3 | Job ID: local_run | Source: DEFAULT | Host: your_host_name
No SLURM or local bash detected: Defaulting to 1 thread.
[ Info: Worker 1 has num_threads = 1
      From worker 3:    [ Info: Worker 3 has num_threads = 1
      From worker 2:    [ Info: Worker 2 has num_threads = 1
      From worker 4:    [ Info: Worker 4 has num_threads = 1
```