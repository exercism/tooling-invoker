# Tooling invoker

## Local Setup

The production version of this code uses `runc`. 
This only works on Linux and not within Docker. 
However, there is a local version available which runs off a locally checked out piece of tooling.
The Dockerfile in this repo has the Ruby Test Runner bundled with it.

To use this, do the following:
- Clone a tooling repo to the directory parallel for this (e.g. `ruby-test-runner`)
- Set a AWS profile called `exercism_tooling_invoker` with an access key and secret.

Tests can be run locally on any system.

To build the Dockerfile, run:
```
docker build -f Dockerfile.dev -t tooking-invoker .
```

To execute the Dockerfile, run the following with your AWS keys:
```
./bin/run-docker $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
```

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

