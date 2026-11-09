# DATABASE_KEY comes from BWS (project "common") at run time via
# with-database-key.sh; it is never in this file or the job env.
job "lighter-rate-limit" {
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    cron             = "*/5 * * * *"
    prohibit_overlap = true
    time_zone        = "UTC"
  }

  group "script-group" {
    count = 1

    task "python-script" {
      driver = "raw_exec"

      config {
        command = "/bin/bash"
        args    = ["/home/admin/preprod/lighter-python/with-database-key.sh", "/home/admin/anaconda3/bin/python", "/home/admin/preprod/lighter-python/examples/create_modify_cancel_order_http.py"]
      }

      resources {
        cpu    = 500
        memory = 512
      }

      env {
        API_CONFIG_DIR = "/home/admin/preprod/lighter-python/examples/api_key_config.json"
      }
    }
  }
}