# nomad-driver-winsvc

A task driver plugin to orchestrate Windows Services as [Hashicorp Nomad](https://www.nomadproject.io/) job tasks. </br>

---

## Configuring the Plugin

A task is configured using the below options:

| Option                  | Type        | Description |
|:------------------------|:-----------:|:------------|
| **executable**          | `string`    | Path to executable binary |
| **args**                | `[]string`  | Command line arguments to pass to executable |
| **service_start_name**  | `string`    | Name of the local account to use (LocalSystem, NT AUTHORITY\\NetworkService) |
| **username**            | `string`    | Name of the account under which the service should run |
| **password**            | `string`    | Password of the account |
| **write_health_script** | `bool`      | When `true`, automatically writes a Windows Service health check PowerShell script into the allocation task directory |
| **health_script_name**  | `string`    | Optional custom name for the generated PowerShell health script (default: `winsvc-health.ps1`) |

---

## Windows Service Health Checks (PowerShell-Based)

The `winsvc` driver can automatically generate a PowerShell health check script for each allocation.

This allows Consul to perform script-based health checks without requiring custom scripts per job.

### How It Works

When `write_health_script = true`:

- The driver writes a PowerShell file into `${NOMAD_TASK_DIR}`
- The script derives the Windows Service name using:
  ```
  nomad.winsvc.<JobName>.<AllocID>
  ```
- The script verifies:
  - Service exists
  - Service status is `Running`
  - A valid Process ID exists
  - The process is alive
- Exit codes:
  - `0` = Healthy
  - Non-zero = Unhealthy

Consul executes this script via a `script` health check.

---

## Example Job With Windows Service Health Check

```hcl
task "example-service" {
  driver = "winsvc"

  config {
    executable          = "local/example.exe"
    service_start_name  = "LocalSystem"

    write_health_script = true
    health_script_name  = "winsvc-health.ps1"
  }

  service {
    name     = "example-service"
    provider = "consul"

    check {
      name     = "winsvc-running"
      type     = "script"
      command  = "powershell.exe"
      args = [
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy", "Bypass",
        "-File", "${NOMAD_TASK_DIR}\\winsvc-health.ps1"
      ]
      interval  = "15s"
      timeout   = "5s"
      on_update = "require_healthy"
    }
  }
}
```

---

## Example Run

```console
PS> nomad job run example/example.nomad
```

This creates Windows services named using:

```
nomad.winsvc.<JobName>.<AllocID>
```

Example:

```console
PS❯ get-service nomad.winsvc.* | select Status, Name, BinaryPathName

Status  Name                                                        BinaryPathName
------  ----                                                        --------------
Running nomad.winsvc.example.e402ad0a-7d7d-e72e-1823-64ba5ded3711   C:\hashicorp\nomad\data\alloc\e402ad0a-7d7d-e72e-1823-64ba5ded3711\task\local\example.exe
Running nomad.winsvc.example.c59a986f-6e14-f14f-d1ac-593cd86025b7   C:\hashicorp\nomad\data\alloc\c59a986f-6e14-f14f-d1ac-593cd86025b7\task\local\example.exe
```

If the Windows service:
- Stops
- Crashes
- Loses its backing process

The Consul health check will fail and Nomad will honor any configured `check_restart` behavior.

---

## Restart Integration

Optional restart behavior:

```hcl
check_restart {
  limit           = 3
  grace           = "90s"
  ignore_warnings = false
}
```

This allows Nomad to automatically restart unhealthy services.

---

## Passing Username/Password as Environment Variables

The service username and password can be passed via environment variables:

```hcl
env {
  NOMAD_WINSVC_USERNAME = "ServiceAccountUsername"
  NOMAD_WINSVC_PASSWORD = "ServiceAccountPassword"
}
```

The driver securely applies these credentials when creating the Windows service.

---

## Behavior on Job Stop

Stopping the job will:

1. Send a graceful stop signal to the Windows Service
2. Wait for the configured shutdown timeout
3. Force terminate remaining processes (if necessary)
4. Remove the Windows Service from the host

After Nomad GC runs, the allocation directory and generated health script are removed.
