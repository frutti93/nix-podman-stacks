{
  tls = {
    options = {
      default = {
        sniStrict = true;
        minVersion = "VersionTLS12";
        cipherSuites = ["TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256" "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384" "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305" "TLS_AES_128_GCM_SHA256" "TLS_AES_256_GCM_SHA384" "TLS_CHACHA20_POLY1305_SHA256"];
        curvePreferences = ["CurveP521" "CurveP384"];
      };
    };
  };
  http = {
    middlewares = {
      public-chain.chain.middlewares = ["public-ratelimit" "security-headers" "geoblock"];
      private-chain.chain.middlewares = ["ipwhitelist-internal"];
      ipwhitelist-internal.ipAllowList.sourceRange = ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"];
      public-ratelimit.rateLimit = {
        average = 100;
        burst = 100;
      };

      geoblock.plugin.geoblock = {
        enabled = true;
        databaseFilePath = "/plugins/geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN";
        allowedCountries = ["DE"];
        allowPrivate = true;
        disallowedStatusCode = 403;
      };

      security-headers.headers = {
        hostsProxyHeaders = ["X-Forwarded-Host"];
        stsSeconds = 63072000;
        stsIncludeSubdomains = true;
        stsPreload = true;
        forceSTSHeader = true;
        customFrameOptionsValue = "SAMEORIGIN";
        browserXssFilter = true;
        referrerPolicy = "same-origin";
        permissionsPolicy = "camera=(), microphone=(), geolocation=(), payment=(), usb=(), vr=()";
        customResponseHeaders = {
          X-Robots-Tag = "none,noarchive,nosnippet,notranslate,noimageindex,";
          server = "";
        };
      };
    };
  };
}
