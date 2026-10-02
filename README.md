# velocity-edge-network-template

![Velocity](https://img.shields.io/badge/Velocity-1F8FFF?logo=minecraft&logoColor=white) ![Geyser](https://img.shields.io/badge/Geyser%2FFloodgate-5865F2) ![nftables](https://img.shields.io/badge/nftables-EE0000?logo=linux&logoColor=white) ![License](https://img.shields.io/badge/License-MIT-green)

> Proxy network template: modern forwarding, Bedrock bridging, and the firewall
> policy that makes the first two safe.

## The one line that matters

```toml
player-info-forwarding-mode = "modern"
```

Forwarding mode decides whether your network is secure:

| Mode | How a backend verifies identity | Risk |
|---|---|---|
| `legacy` | Trusts the connection | Anyone reaching a backend port joins as any player |
| `bungeeguard` | Shared token in the handshake | Token leak = full impersonation |
| `modern` | **Cryptographic signature** | Signature cannot be forged |

With `modern`, a reachable backend port is not sufficient to impersonate anyone.
The firewall below is then defence in depth rather than the only thing standing
between you and compromise.

## Why the firewall is still included

```
tcp dport 25566-25570 ip saddr $PROXY_HOST accept
tcp dport 25566-25570 drop                      # backends are never public
```

Backends run `online-mode=false` (the proxy authenticates), so a directly
reachable backend with weak forwarding accepts any username offered. This rule
is the difference between a misconfiguration being an inconvenience and being a
full compromise.

Also enforced:

- RCON (25575) bound to loopback only — the protocol sends its password in cleartext
- Redis and MySQL restricted to the backend subnet
- Login rate limiting (10/min per source) so one host cannot exhaust the login queue
- SSH restricted to an admin network

```bash
sudo nft -f firewall/nftables.conf
sudo nft list ruleset        # verify before you log out
```

## Bedrock support

Geyser runs **on the proxy**, not on backends. Bedrock clients connect over UDP
to 19132; Geyser translates to Java protocol and hands them to Velocity as
ordinary players.

```yaml
remote:
  auth-type: floodgate    # required: Bedrock players have no Java account
```

Floodgate supplies the authentication a Bedrock client cannot provide itself.
Without it, Bedrock players cannot be verified at all.

## Forwarding secret

```bash
openssl rand -base64 48 > velocity/forwarding.secret
chmod 600 velocity/forwarding.secret
```

This value must match `proxies.velocity.secret` in **every** backend's
`paper-global.yml`. A mismatch kicks players with "Unable to verify player
details". Treat it as a password: anyone holding it can join any backend as
anyone.

## Compression alignment

```toml
compression-threshold = 256    # must match backend network-compression-threshold
```

A mismatch means every packet is decompressed and recompressed at the proxy —
pure wasted CPU on the busiest hop in the network.

## Topology

```
                   ┌─────────────┐
   Java  :25565 ───▶│             │───▶ lobby-01    :25566
                   │  Velocity   │───▶ lobby-02    :25567
Bedrock  :19132 ───▶│  + Geyser   │───▶ survival-01 :25568
                   │             │───▶ skyblock-01 :25569
                   └─────────────┘───▶ prison-01   :25570
                      (public)           (firewalled to proxy)
```

`try = ["lobby-01", "lobby-02"]` — two lobbies means a lobby restart does not
lock players out of the network.

## License

MIT — see [LICENSE](LICENSE).
