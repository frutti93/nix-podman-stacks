# Integration test for the shipped template config (template/stacks.nix +
# template/sops.nix). Deploys the starter configuration as a whole, so it covers the
# cross-stack wiring a single stack's vm-test.nix cannot: sops-nix secret decryption,
# the authelia -> lldap -> app OIDC chain, and the monitoring stack.
{
  self,
  pkgs,
}:
self.lib.mkIntegrationTest {
  inherit pkgs;
  name = "template-integration";
  modules = [
    self.inputs.sops-nix.homeManagerModules.sops
    ../template/sops.nix
    ../template/stacks.nix

    # Traefik would otherwise try to issue a real Let's Encrypt certificate.
    self.lib.stackTestModules.traefik
  ];
  memorySize = 4096;
  diskSize = 20480;
  waitTimeout = 1800;
}
