using Test
using SimplexThreeGT: SimplexThreeGT, with_path_log

with_path_log(pkgdir(SimplexThreeGT, "test", "logs"), "test") do
    @info "Hello, world!"
end

@test isfile(pkgdir(SimplexThreeGT, "test", "logs", "test.log"))
