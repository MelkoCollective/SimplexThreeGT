using Configurations
using UUIDs: UUID, uuid1
using SimplexThreeGT.Jobs

job = AnnealingJob(;
    uuid = uuid1(),
    njobs = 10,
    shape = ShapeInfo(;
        ndims = 3,
        size = 8,
        p = 3,
    ),
    storage = StorageInfo(;
        path = "data",
        tags = ["test"],
    ),
    sample = SamplingInfo(;
        nburns = 1000,
        order = Random,
        gauge = nothing,
    ),
    temperatures = 10:-0.1:0.1,
    fields = 0:0.01:1,
)

rjob = ResampleJob(;
    uuid=uuid1(),
    njobs=800,
    parent=job.uuid,
    shape = ShapeInfo(;
        ndims = 3,
        size = 8,
        p = 3,
    ),
    storage=StorageInfo(;
        path="data",
        tags=["test"],
    ),
    sample=ResampleInfo(;
        nrepeat=10,
        nthrows=1000,
        nsamples=1000,
        option=SamplingInfo(;
            nburns=1000,
            order=Random,
            gauge=nothing,
        ),
        observables=["E", "E^2"],
    ),
    fields=0:0.01:1,
    temperatures=2:-0.1:0.1,
)


Jobs.emit(job, rjob)
