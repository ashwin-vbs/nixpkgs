test@{ config, lib, params, ... }:
let
  inherit (lib) optionalString mkOption;
  inherit (params) domain;
  hostName = "ahost";
  fqdnOrNull = if domain == null then null else fqdn;
  fqdn = hostName + (optionalString (domain != null) ".${domain}");

  getStr = str: # maybeString2String
    let res = builtins.tryEval str;
    in if (res.success && res.value != null) then res.value else "null";

in
{
  meta = with lib.maintainers; {
    maintainers = [ primeos blitz ];
  };

  name = "hostname-${fqdn}";

  matrix.domain.choice.explicit.module.params.domain = "adomain";
  matrix.domain.choice.implicit.module.params.domain = null;

  nodes.machine = { lib, pkgs, ... }: {
    networking.hostName = hostName;
    networking.domain = domain;

    environment.systemPackages = with pkgs; [
      inetutils
    ];
  };

  testScript = { nodes, ... }: ''
    start_all()

    machine = ${hostName}

    machine.wait_for_unit("network-online.target")

    # Test if NixOS computes the correct FQDN (either a FQDN or an error/null):
    assert "${getStr nodes.machine.networking.fqdn}" == "${getStr fqdnOrNull}"

    # The FQDN, domain name, and hostname detection should work as expected:
    assert "${fqdn}" == machine.succeed("hostname --fqdn").strip()
    assert "${optionalString (domain != null) domain}" == machine.succeed("dnsdomainname").strip()
    assert (
        "${hostName}"
        == machine.succeed(
            'hostnamectl status | grep "Static hostname" | cut -d: -f2'
        ).strip()
    )

    # 127.0.0.1 and ::1 should resolve back to "localhost":
    assert (
        "localhost" == machine.succeed("getent hosts 127.0.0.1 | awk '{print $2}'").strip()
    )
    assert "localhost" == machine.succeed("getent hosts ::1 | awk '{print $2}'").strip()

    # 127.0.0.2 should resolve back to the FQDN and hostname:
    fqdn_and_host_name = "${optionalString (domain != null) "${hostName}.${domain} "}${hostName}"
    assert (
        fqdn_and_host_name
        == machine.succeed("getent hosts 127.0.0.2 | awk '{print $2,$3}'").strip()
    )
  '';
}
