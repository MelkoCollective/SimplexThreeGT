using Test
using SimplexThreeGT.Homology: CellMap, cell_points, cell_topology, Point


@test CellMap(2, 3, (1, 2)) == CellMap(
    2, 3, (1, 2),
    Dict(
        1 => Set([1, 7]),
        2 => Set([2, 8]),
        3 => Set([3, 9]),
        4 => Set([1, 4]),
        5 => Set([2, 5]),
        6 => Set([3, 6]),
        7 => Set([4, 7]),
        8 => Set([5, 8]),
        9 => Set([6, 9]),
        10 => Set([1, 3]),
        11 => Set([4, 6]),
        12 => Set([7, 9]),
        13 => Set([1, 2]),
        14 => Set([4, 5]),
        15 => Set([7, 8]),
        16 => Set([2, 3]),
        17 => Set([5, 6]),
        18 => Set([8, 9]),
    ),
    Dict(
        1 => Set([1, 10, 4, 13]),
        2 => Set([2, 13, 5, 16]),
        3 => Set([3, 16, 6, 10]),
        4 => Set([4, 11, 7, 14]),
        5 => Set([5, 14, 8, 17]),
        6 => Set([6, 17, 9, 11]),
        7 => Set([7, 12, 1, 15]),
        8 => Set([8, 15, 2, 18]),
        9 => Set([9, 18, 3, 12]),
    ),
)


@test CellMap(2, 3, (0, 1)) == CellMap(
    2, 3, (0, 1),

    Dict(
        1 => Set([1, 10, 12, 3]),
        2 => Set([2, 13, 1, 15]),
        3 => Set([3, 16, 2, 18]),
        4 => Set([4, 11, 6, 10]),
        5 => Set([5, 14, 4, 13]),
        6 => Set([6, 17, 5, 16]),
        7 => Set([7, 12, 9, 11]),
        8 => Set([8, 15, 7, 14]),
        9 => Set([9, 18, 8, 17]),
    ),

    Dict(
        1 => Set([1, 2]),
        2 => Set([2, 3]),
        3 => Set([3, 1]),
        4 => Set([4, 5]),
        5 => Set([5, 6]),
        6 => Set([6, 4]),
        7 => Set([7, 8]),
        8 => Set([8, 9]),
        9 => Set([9, 7]),
        10 => Set([1, 4]),
        11 => Set([4, 7]),
        12 => Set([7, 1]),
        13 => Set([2, 5]),
        14 => Set([5, 8]),
        15 => Set([8, 2]),
        16 => Set([3, 6]),
        17 => Set([6, 9]),
        18 => Set([9, 3]),
    ),
)
