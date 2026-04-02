# WebRTC Outpost

Configuration repository for a Coturn relay that supports a Stoat deployment on GCP. The stack provisions a `relay-main` Ubuntu 24.04 instance, hardens the host with `nftables`, `fail2ban`, and `unattended-upgrades`, then deploys Coturn plus a Coraza-enabled Caddy service with Podman Compose. Caddy handles ACME certificate issuance, HTTPS health checks, and deny-by-default web responses on the TURN hostname. Coturn handles STUN and TURN traffic directly on `3478` and `5349`, reusing the certificate that Caddy stores in the shared data volume.

## Repository Layout

- `tofu/`: OpenTofu infrastructure for the static IP, VM, and GCP firewall rule.
- `ansible/`: Host preparation and hardening for Ubuntu 24.04.
- `compose/`: Runtime configuration for Coturn and Caddy.
- `docker/`: Custom images for Coturn and Caddy.
- `.github/workflows/`: CI workflows for building images and deploying the stack.

## Required GitHub Secrets

- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `CLOUDFLARE_ACCOUNT_ID`
- `GCP_SA_KEY`
- `SSH_PRIVATE_KEY`
- `TURN_SHARED_SECRET`

## Recommended GitHub Variables

- `GCP_PROJECT`
- `GCP_REGION`
- `GCP_ZONE`
- `TURN_REALM`
- `CADDY_EMAIL`

## Notes

- The OpenTofu S3 backend is configured at deploy time so the Cloudflare R2 endpoint does not need to be committed to the repository.
- The Google provider reads service account credentials from the standard `GOOGLE_APPLICATION_CREDENTIALS` shell environment variable. Set it to the JSON key file path for local `tofu` runs.
- The custom Coturn image waits for the Caddy-managed certificate for `TURN_REALM` to appear in the shared `caddy_data` volume before starting the TLS listener on `5349`.
- Caddy on the relay host only answers `/health` and returns `403` for other HTTPS requests. TURN and STUN traffic does not pass through Caddy; Coturn receives it directly through host networking.
- The Ansible playbook lowers `net.ipv4.ip_unprivileged_port_start` to `80` so a rootless Podman-managed Caddy container can bind to `80` and `443`.

## DNS Setup

- Create a DNS `A` record so the hostname used by `TURN_REALM` resolves to the OpenTofu-provisioned `relay_ip`.
- If you use Cloudflare, keep that record set to DNS-only. The orange-cloud proxy does not support TURN or STUN over UDP.
- Optional SRV records can advertise the default ports: `_stun._udp` on `3478`, `_turn._udp` on `3478`, and `_turns._tcp` on `5349` for the same hostname.

## Local OpenTofu Usage

Export the Google credentials path and required OpenTofu variables before running `tofu` locally:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="secret-path"
export TF_VAR_gcp_project="your-gcp-project"
export TF_VAR_gcp_region="us-west1"
export TF_VAR_gcp_zone="us-west1-b"

cd tofu
tofu init
tofu apply
```

`network_name` defaults to `default`, `instance_name` defaults to `relay-main`, and `admin_ssh_public_key` is optional unless you want SSH access provisioned on the VM.
