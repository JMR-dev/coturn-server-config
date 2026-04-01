# WebRTC Outpost

Configuration repository for a Coturn relay that supports a Stoat deployment on GCP. The stack provisions a `relay-main` Ubuntu 24.04 instance, hardens the host with `nftables`, `fail2ban`, and `unattended-upgrades`, then deploys Coturn plus a Coraza-enabled Caddy reverse proxy with Podman Compose.

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
- `CADDY_DOMAIN`
- `CADDY_EMAIL`
- `STOAT_UPSTREAM`
- `TURN_TLS_CERT_FILE`
- `TURN_TLS_KEY_FILE`

## Notes

- The OpenTofu S3 backend is configured at deploy time so the Cloudflare R2 endpoint does not need to be committed to the repository.
- The Google provider reads service account credentials from the standard `GOOGLE_APPLICATION_CREDENTIALS` shell environment variable. Set it to the JSON key file path for local `tofu` runs.
- The custom Coturn image renders runtime settings from environment variables before starting `turnserver`.
- `TURN_TLS_CERT_FILE` and `TURN_TLS_KEY_FILE` are optional. If they are omitted, Coturn starts on `3478` only and skips the `5349` TLS listener.
- The Ansible playbook lowers `net.ipv4.ip_unprivileged_port_start` to `80` so a rootless Podman-managed Caddy container can bind to `80` and `443`.

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
