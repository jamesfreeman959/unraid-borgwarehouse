<!-- Draft for the Unraid forums, Docker Containers section. Title: [Support] BorgWarehouse -->

**BorgWarehouse** is a web interface for running your own BorgBackup server. It turns Unraid into the backup
destination for your other machines (borg, Vorta, borgmatic over SSH), with repository and SSH key management,
quotas, backup status monitoring and email/Apprise alerts for late backups.

- Application: https://borgwarehouse.com (by Ravinou)
- Upstream source and issues: https://github.com/Ravinou/borgwarehouse
- Docker Hub: https://hub.docker.com/r/borgwarehouse/borgwarehouse
- Template repository: https://github.com/jamesfreeman959/unraid-borgwarehouse

The template uses the official image unchanged.

**Setup**

1. Generate two secrets in the Unraid terminal with `openssl rand -base64 32` and use them for
   BETTER_AUTH_SECRET and CRONJOB_KEY.
2. SSH port: Unraid's own SSH uses 22, so the template maps BorgWarehouse's SSH to 2222. Set SSH_SERVER_PORT to
   the same value. Clients connect to this port.
3. Set FQDN to the hostname/IP your clients use, and BETTER_AUTH_URL to the URL you open the web UI at. If you
   use more than one address (e.g. a reverse proxy domain and http://IP:3000), put the others in
   BETTER_AUTH_TRUSTED_ORIGINS, otherwise login fails with "Invalid origin" in the log.
4. Point Repositories at a share sized for your backups, not appdata.

**Scheduled checks:** BorgWarehouse needs an hourly call to update backup status and storage use and to send
late-backup alerts. Install the User Scripts plugin and add this script with a custom schedule of `0 * * * *`:
https://github.com/jamesfreeman959/unraid-borgwarehouse/blob/main/scripts/borgwarehouse-cron.sh

**SSO:** OIDC (Authentik, Keycloak, Zitadel, ...) is under Show more settings. The redirect URI is
`<BETTER_AUTH_URL>/api/auth/callback/oidc`. SSO only signs in existing users, so the BorgWarehouse
account's email must match the one your provider sends.

**Known issue (BorgWarehouse 3.7.0):** a brand new install fails on its first start with
"Database schema mismatch" / error 500. Restart the container once and it works. Reported upstream.

Please post your container log (Docker tab → BorgWarehouse icon → Logs) with any problem, with secrets removed.
