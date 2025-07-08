{
  global = {
    scrape_interval = "1m";
    scrape_timeout = "10s";
    evaluation_interval = "1m";
  };
  alerting = {
    alertmanagers = [
      {
        static_configs = [{targets = [];}];
        scheme = "http";
        timeout = "10s";
        api_version = "v2";
      }
    ];
  };
  scrape_configs = [
    {
      job_name = "prometheus";
      honor_timestamps = true;
      metrics_path = "/metrics";
      scheme = "http";
      static_configs = [{targets = ["localhost:9090"];}];
    }
  ];
}
