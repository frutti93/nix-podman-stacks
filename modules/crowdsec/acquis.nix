{
  source = "docker";
  container_name = ["traefik"];
  labels = {
    type = "traefik";
  };
}
