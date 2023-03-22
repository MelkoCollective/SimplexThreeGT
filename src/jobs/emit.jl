function emit(job::AnnealingJob)
    to_toml(temp_image_dir(job, "cellmap.toml"), job.cellmap)
    foreach(job.tasks) do task::AnnealingTask
        option = AnnealingOptions(;
            uuid = task.uuid,
            seed = job.seed,
            cellmap = job.cellmap.shape,
            storage = job.storage,
            nburns = job.nburns,
            order = job.order,
            gauge = job.cellmap.gauge,
            temperature = job.temperature,
            field = task.field,
        )
        to_toml(temp_image_dir(job, "annealing-$(task.uuid).toml"), option)

        resample = task.resample::ResampleInfo
        for sample_task in resample.tasks
            option = ResampleOptions(;
                seed = sample_task.seed,
                uuid = sample_task.uuid,
                parent = task.uuid,
                cellmap = job.cellmap.shape,
                storage = job.storage,
                sample = resample.sample,
                nrepeat = resample.nrepeat,
                fields = [task.field],
                temperatures = sample_task.temperatures,
            )
        end
    end
end
