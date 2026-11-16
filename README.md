# Tooling Invoker
![Tests](https://github.com/exercism/tooling-invoker/workflows/Tests/badge.svg)

## Local Setup

The production version of this code uses `runc`.
This only works on Linux and not within Docker.
However, there is a local version available which runs off a locally checked out piece of tooling.

To use this, do the following:
- Clone a tooling repo to the directory parallel for this (e.g. `ruby-test-runner`)
- Set a AWS profile called `exercism_tooling_invoker` with an access key and secret.

Tests can be run locally on any system.

To build the Dockerfile, run:
```
docker build -f Dockerfile.dev -t exercism-tooking-invoker .
```

To execute the Dockerfile, run the following with your AWS keys:
```
./bin/run-docker $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
```

### Running Tests inside Docker

Note: Tests can be run without the full [v3-docker-compose](https://github.com/exercism/v3-docker-compose/) stack

```bash
# to run bundle exec rake test
./docker/test
```

Or to jump into a console, then just run commands as normal:

```bash
./docker/console
{^_^} tooling-invoker
      /usr/src/app % bundle exec rake test
```

## Each job ends with a status code

Each job's result carries one of these statuses, defined in `lib/tooling_invoker/jobs/job.rb`:

| Status | Meaning |
| --- | --- |
| 200 | The tool ran and exited cleanly |
| 408 | The tool timed out |
| 410 | The tool did not run |
| 413 | The tool wrote too much to stdout or stderr |
| 460 | The tool's output files were too large |
| 512 | The invoker could not prepare the job's input |
| 513 | An unknown error occurred |
| 514 | The orchestrator gave up on the job after repeated attempts. The invoker never sets this. |

## Filesystem Layout

_This is WIP_

The containers live in a directory (currently `CONTAINERS_DIR` but will be in config).

Each iteration is then hosted as follows:

```
- containers
  - ruby
    - releases
      - xxx
    - current (symlink to a releases sha)
    - runs
      - iteration_xxx-iteration_slug-xxx (iteration_dir)
        - code
          - ...user's code
        - config.json (symlink to invocation_config.json)
```

Within the runc environment we have:
```
- /opt
    - container_tools
      - runc
    - test-runner (or /opt/analyzer or /opt/representer)

```

## Layout within containers

