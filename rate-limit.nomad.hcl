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
        command = "/home/admin/anaconda3/bin/python"
        args    = ["/home/admin/preprod/lighter-python/examples/create_modify_cancel_order_http.py"]
      }

      resources {
        cpu    = 500
        memory = 512
      }

      env {
        DB_KEY = "yOQQap7831p5k"
        API_CONFIG_DIR = "/home/admin/preprod/lighter-python/examples/api_key_config.json"
      }
    }
  }
}