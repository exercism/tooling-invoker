# Tooling invoker

## Layout

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

