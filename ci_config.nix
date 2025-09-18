# Full configuration of every stack to catch potential errors in CI pipeline
# Secrets etc. will be not read from file / available in Nix store. Don't do this at home :)
{
  config,
  lib,
  pkgs,
  ...
}: let
  dummyId = "dummy";
  dummySecret = "insecure_secret";
  dummySecretFile = "${pkgs.writeText "insecure_secret" dummySecret}";
  dummyHash = "$argon2id$v=19$m=65536,t=3,p=4$8USywQgWNhOf4drzlVTieA$Rm8SlHy+ipThtIa/6nMMir2QkoXESCr4uCB2aAdvlmo";
  dummyUser = "admin";
  dummyEmail = "admin@example.com";
in {
  config.nps = rec {
    hostIP4Address = "192.168.178.2";
    hostUid = 1000;
    storageBaseDir = "${config.home.homeDirectory}/stacks";
    externalStorageBaseDir = "/mnt/hdd";
    defaultTz = "Europe/Berlin";

    stacks = {
      adguard.enable = true;

      aiostreams = {
        enable = true;
        extraEnv = {
          SECRET_KEY.fromFile = dummySecretFile;
        };
      };

      authelia = {
        enable = true;
        jwtSecretFile = dummySecretFile;
        sessionSecretFile = dummySecretFile;
        storageEncryptionKeyFile = dummySecretFile;

        oidc = {
          enable = true;
          hmacSecretFile = dummySecretFile;
          jwksRsaKeyFile = dummySecretFile;

          clients.dummy = {
            public = true;
            authorization_policy = "two_factor";
            redirect_uris = [];
          };
        };
        settings.access_control.rules = [
          {
            domain = "private.example.com";
            subject = [
              "group:guest"
            ];
            policy = "deny";
          }
        ];
      };

      baikal.enable = true;

      beszel = {
        enable = true;
        ed25519PrivateKeyFile = dummySecretFile;
        ed25519PublicKeyFile = dummySecretFile;
        oidc = {
          registerClient = true;
          clientSecretHash = dummyHash;
        };
      };

      blocky = {
        enable = true;
        enableGrafanaDashboard = true;
        enablePrometheusExport = true;
        containers.blocky = {
          homepage.settings.href = "${config.nps.containers.grafana.traefik.serviceUrl}/d/blocky";
          gatus = {
            enable = true;
            settings = {
              url = "host.containers.internal";
              dns = {
                query-name = config.nps.stacks.traefik.domain;
                query-type = "A";
              };
              conditions = [
                "[DNS_RCODE] == NOERROR"
              ];
            };
          };
        };
      };

      bytestash = {
        enable = true;
        extraEnv.JWT_SECRET.fromFile = dummySecretFile;
      };

      calibre.enable = true;

      changedetection.enable = true;

      crowdsec = {
        enable = true;
        extraEnv = {
          ENROLL_INSTANCE_NAME = "dummy";
          ENROLL_KEY.fromFile = dummySecretFile;
        };
      };

      davis = {
        adminPasswordFile = dummySecret;
        enableLdapAuth = true;
        db = {
          type = "mysql";
          userPasswordFile = dummySecret;
          rootPasswordFile = dummySecret;
        };
      };

      dockdns = {
        enable = true;
        extraEnv.EXAMPLE_COM_API_TOKEN.fromFile = dummySecretFile;
        settings.dns.purgeUnknown = true;
        settings.domains = let
          domain = config.nps.stacks.traefik.domain;
        in [
          {
            name = domain;
            a = hostIP4Address;
          }
          {
            name = "*.${domain}";
            a = hostIP4Address;
          }
        ];
      };

      docker-socket-proxy.enable = true;

      donetick = {
        jwtSecretFile = dummySecretFile;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        settings.is_user_creation_disabled = true;
      };

      dozzle = {
        enable = true;
        containers.dozzle.forwardAuth = {
          enable = true;
          rules = [
            {
              policy = "one_factor";
            }
          ];
        };
      };

      filebrowser = {
        enable = true;
        mounts = {
          "/home/foo/bar" = "/bar";
        };
      };

      filebrowser-quantum = {
        enable = true;
        mounts = {
          ${config.nps.externalStorageBaseDir} = {
            path = "/hdd";
            name = "hdd";
            config = {
              denyByDefault = true;
              disableIndexing = false;
            };
          };
        };
        oidc = {
          enable = true;
          clientSecretHash = dummyHash;
          clientSecretFile = dummySecretFile;
        };
        settings.auth.methods.password.enabled = false;
      };

      forgejo = {
        enable = true;
        settings = {
          DEFAULT = {
            RUN_MODE = "dev";
          };
          other = {
            SHOW_FOOTER_VERSION = false;
          };
        };
      };

      freshrss = {
        enable = true;
        adminProvisioning = {
          enable = true;
          username = dummyUser;
          email = dummyEmail;
          passwordFile = dummySecretFile;
          apiPasswordFile = dummySecretFile;
        };
      };

      gatus = {
        enable = true;
        db = {
          type = "postgres";
          passwordFile = dummySecretFile;
        };

        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
      };

      guacamole = {
        enable = true;
        userMappingXml = pkgs.writeText "user-mapping.xml" ''
          <user-mapping>
            <authorize username="${dummyUser}" password="${dummySecret}">
                <connection name="SSH">
                    <protocol>ssh</protocol>
                    <param name="hostname">host.containers.internal</param>
                    <param name="port">22</param>
                </connection>
                <connection name="RDP">
                  <protocol>rdp</protocol>
                  <param name="hostname">103.5.133.3</param>
                  <param name="port">22</param>
                </connection>
            </authorize>
          </user-mapping>
        '';
      };

      healthchecks = {
        enable = true;
        secretKeyFile = dummySecretFile;
        superUserEmail = dummyEmail;
        superUserPasswordFile = dummySecretFile;
      };

      homeassistant.enable = true;

      homepage = {
        enable = true;
        widgets = [
          {
            openweathermap = {
              units = "metric";
              cache = 5;
              apiKey.path = dummySecretFile;
            };
          }
        ];
      };

      immich = {
        enable = true;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        dbPasswordFile = dummySecretFile;
      };

      ittools.enable = true;

      karakeep = {
        enable = true;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        nextauthSecretFile = dummySecretFile;
        meiliMasterKeyFile = dummySecretFile;
      };

      kimai = {
        enable = true;
        adminEmail = dummyEmail;
        adminPasswordFile = dummySecretFile;
        db = {
          userPasswordFile = dummySecretFile;
          rootPasswordFile = dummySecretFile;
        };
      };

      komga = {
        enable = true;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
      };

      lldap = {
        enable = true;
        baseDn = "DC=example,DC=com";
        jwtSecretFile = dummySecretFile;
        keySeedFile = dummySecretFile;
        adminPasswordFile = dummySecretFile;
        bootstrap = {
          cleanUp = true;
          users = {
            test = {
              email = dummyEmail;
              password_file = dummySecretFile;
            };
          };
        };
      };

      mazanoke.enable = true;

      mealie = {
        enable = true;
        oidc = {
          enable = true;
          clientSecretHash = dummyHash;
          clientSecretFile = dummySecretFile;
        };
      };

      memos = {
        enable = true;
        oidc = {
          registerClient = true;
          clientSecretHash = dummyHash;
        };
        db = {
          type = "postgres";
          passwordFile = dummySecretFile;
        };
      };

      microbin = {
        enable = true;
        extraEnv = {
          MICROBIN_ADMIN_USERNAME = dummyUser;
          MICROBIN_ADMIN_PASSWORD.fromFile = dummySecretFile;
          MICROBIN_UPLOADER_PASSWORD.fromFile = dummySecretFile;
        };
      };

      monitoring.enable = true;

      n8n.enable = true;

      ntfy = {
        enable = true;
        extraEnv = {
          NTFY_WEB_PUSH_EMAIL_ADDRESS = dummyEmail;
          NTFY_WEB_PUSH_PUBLIC_KEY.fromFile = dummySecretFile;
          NTFY_WEB_PUSH_PRIVATE_KEY.fromFile = dummySecretFile;
        };
        enableGrafanaDashboard = true;
        enablePrometheusExport = true;
      };

      omnitools.enable = true;

      outline = {
        enable = true;
        secretKeyFile = dummySecretFile;
        utilsSecretFile = dummySecretFile;
        db.passwordFile = dummySecretFile;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
      };

      paperless = {
        enable = true;
        adminProvisioning = {
          username = dummyUser;
          email = dummyEmail;
          passwordFile = dummySecretFile;
        };
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        secretKeyFile = dummySecretFile;
        extraEnv = {
          PAPERLESS_OCR_LANGUAGES = "eng deu";
          PAPERLESS_OCR_LANGUAGE = "eng+deu";
        };
        db = {
          passwordFile = dummySecretFile;
        };
        ftp = {
          enable = true;
          passwordFile = dummySecretFile;
        };
      };

      pocketid = {
        enable = true;
        traefikIntegration = {
          enable = true;
          clientId = dummyId;
          clientSecretFile = dummySecretFile;
          encryptionSecretFile = dummySecretFile;
        };
      };

      romm = {
        enable = true;
        adminProvisioning = {
          enable = true;
          username = dummyUser;
          passwordFile = dummySecretFile;
          email = dummyEmail;
        };
        authSecretKeyFile = dummySecretFile;
        romLibraryPath = "${config.nps.externalStorageBaseDir}/romm/library";
        extraEnv = {
          IGDB_CLIENT_ID.fromFile = dummySecretFile;
          IGDB_CLIENT_SECRET.fromFile = dummySecretFile;
        };
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        db = {
          userPasswordFile = dummySecretFile;
          rootPasswordFile = dummySecretFile;
        };
      };

      sshwifty = {
        enable = true;
        settings = {
          SharedKey = dummySecret;
          Presets = [
            {
              Title = "Host SSH";
              Type = "SSH";
              Host = "host.containers.internal:22";
              Meta = {
                User = dummyId;
                Encoding = "utf-8";
                "Private Key" = "file://${dummySecretFile}";
                Authentication = "Private Key";
              };
            }
          ];
        };
      };

      stirling-pdf.enable = true;

      storyteller = {
        enable = true;
        secretKeyFile = dummySecretFile;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
      };

      streaming =
        {
          enable = true;
          gluetun = {
            vpnProvider = "airvpn";
            wireguardPrivateKeyFile = dummySecretFile;
            wireguardPresharedKeyFile = dummySecretFile;
            wireguardAddressesFile = dummySecretFile;

            extraEnv = {
              FIREWALL_VPN_INPUT_PORTS.fromFile = dummySecretFile;
              SERVER_NAMES.fromFile = dummySecretFile;
              HTTP_CONTROL_SERVER_LOG = "off";
            };
          };
          qbittorrent.extraEnv = {
            TORRENTING_PORT.fromFile = dummySecretFile;
          };
          jellyfin = {
            oidc = {
              enable = true;
              clientSecretFile = dummySecretFile;
              clientSecretHash = dummyHash;
            };
          };
        }
        // lib.genAttrs ["sonarr" "radarr" "bazarr" "prowlarr"] (name: {
          extraEnv."${lib.toUpper name}__AUTH__APIKEY".fromFile = dummySecretFile;
        });

      traefik = {
        enable = true;
        domain = "example.com";
        extraEnv.CF_DNS_API_TOKEN.fromFile = dummySecretFile;
        geoblock.allowedCountries = ["DE"];
        enablePrometheusExport = true;
        enableGrafanaMetricsDashboard = true;
        enableGrafanaAccessLogDashboard = true;
        crowdsec.middleware.bouncerKeyFile = dummySecretFile;
      };

      uptime-kuma.enable = true;

      vaultwarden.enable = true;

      vikunja = {
        enable = true;
        db.type = "postgres";
        db.passwordFile = dummySecretFile;
        jwtSecretFile = dummySecretFile;
        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
        settings = {
          service.enableregistration = false;
          auth.local.enabled = false;
        };
      };

      wg-easy = {
        enable = true;
        extraEnv = {
          INIT_PASSWORD.fromFile = dummySecretFile;
          DISABLE_IPV6 = true;
        };
      };

      wg-portal = {
        enable = true;
        settings.core = {
          admin_user = dummyUser;
          admin_password = "\${ADMIN_PASSWORD}";
        };
        extraEnv.ADMIN_PASSWORD.fromFile = dummySecretFile;
        settings.advanved.use_ip_v6 = false;

        oidc = {
          enable = true;
          clientSecretFile = dummySecretFile;
          clientSecretHash = dummyHash;
        };
      };
    };
  };
}
