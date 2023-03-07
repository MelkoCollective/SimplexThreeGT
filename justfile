coverage:
    #!/usr/bin/env julia --project
    using LocalCoverage
    c = generate_coverage("SimplexThreeGT"; run_test = true)
    html_coverage(c; open=true)
