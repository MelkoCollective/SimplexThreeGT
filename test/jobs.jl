using Configurations
using UUIDs: UUID, uuid1
using SimplexThreeGT.Jobs

info = AnnealingJob(;
    uuid=uuid1(),
    storage=StorageInfo(;
        path="data",
        tags=["test"],
    ),
    cellmap=CellMap(;
        shape=ShapeInfo(;
            ndims=3,
            size=4,
            p=2,
        ),
        gauge=2,
        nthreads=1,
    ),
    seed=1234,
    nburns=1000,
    order=Random,
    temperature=1.0:-0.1:0.0,
    tasks=[
        AnnealingTask(
            field=0.0,
            resample=ResampleInfo(
                nrepeat=10,
                sample=SamplingInfo(
                    nburns=1000,
                    nthrows=1000,
                    nsamples=1000,
                    order=Random,
                    observables=["E", "E^2", "M", "M^2"],
                ),
                tasks=[
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.0, 0.1, 0.2],
                    ),
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.3, 0.4, 0.5],
                    )
                ]
            )
        ),
    ]
)

njobs(info)
time_complexity(info)

s = to_toml(info)
using TOML
d = TOML.parse(s)
from_dict(TaskInfo, d)

info = ResampleJob(;
    uuid=uuid1(),
    storage=StorageInfo(;
        path="data",
        tags=["test"],
    ),
    cellmap=CellMap(;
        shape=ShapeInfo(;
            ndims=3,
            size=4,
            p=3,
        ),
        gauge=2,
        nthreads=1,
    ),
    tasks=[
        FieldResample(;
            field=0.0,
            resample=ResampleInfo(
                nrepeat=10,
                sample=SamplingInfo(
                    nburns=1000,
                    nthrows=1000,
                    nsamples=1000,
                    order=Random,
                    observables=["E", "E^2", "M", "M^2"],
                ),
                tasks=[
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.0, 0.1, 0.2],
                    ),
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.3, 0.4, 0.5],
                    )
                ]
            )
        ),
        FieldResample(;
            field=0.1,
            resample=ResampleInfo(
                nrepeat=10,
                sample=SamplingInfo(
                    nburns=1000,
                    nthrows=1000,
                    nsamples=1000,
                    order=Random,
                    observables=["E", "E^2", "M", "M^2"],
                ),
                tasks=[
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.0, 0.1, 0.2],
                    ),
                    ResampleTask(;
                        seed=1234,
                        uuid=uuid1(),
                        temperatures=[0.3, 0.4, 0.5],
                    )
                ]
            )
        ),
    ]
)

njobs(info)
time_complexity(info) * 1e-6 / 60
nspins(info)
