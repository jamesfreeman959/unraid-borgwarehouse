<img src="icon.png" alt="" width="96" align="right">

# BorgWarehouse for Unraid

A Community Applications template for [BorgWarehouse](https://borgwarehouse.com), a web interface for running
your own [BorgBackup](https://www.borgbackup.org) server. With it, your Unraid server becomes the destination
for Borg backups from your other machines (borg, Vorta, borgmatic).

The template uses the official `borgwarehouse/borgwarehouse` image unchanged. This repository only holds the
Unraid template, a User Scripts script for the scheduled checks, and these notes.

## Install

Search for **BorgWarehouse** in the **Apps** tab (Community Applications).

Before you click Apply, fill in:

| Setting | What to put |
| --- | --- |
| **SSH port** / `SSH_SERVER_PORT` | The same port in both. The default is 2222, because Unraid's own SSH uses 22. |
| `FQDN` | The hostname or IP your clients use to reach Unraid, e.g. `tower.local`. |
| `BETTER_AUTH_URL` | The main URL you open the web UI at, e.g. `https://borg.example.com` or `http://192.168.1.10:3000`. If you also use other addresses (say both the proxy domain and the IP), list them in `BETTER_AUTH_TRUSTED_ORIGINS`. Otherwise logins from them fail and the log shows `Invalid origin`. |
| `BETTER_AUTH_SECRET`, `CRONJOB_KEY` | Two different random values. In the Unraid terminal run `openssl rand -base64 32` twice. |
| **Repositories** | A share for the backups themselves, `/mnt/user/borgwarehouse/` by default. Don't use appdata: backups get large. |

Then open the web UI and create the admin account.

> **Known issue in BorgWarehouse 3.7.0:** on a brand new install, the first start fails with
> `Database schema mismatch ... table account has no column named issuer` and the web UI returns error 500.
> Restart the container once and it works. This is an upstream bug (3.6.3 starts cleanly). Existing installs
> upgrading from 3.6.x hit a related problem, tracked in
> [Ravinou/borgwarehouse#723](https://github.com/Ravinou/borgwarehouse/issues/723).

## Scheduled checks (User Scripts)

BorgWarehouse doesn't schedule its own status and storage checks. Something outside the container has to call
them, otherwise the dashboard never updates "last backup" times or storage usage, and late-backup alerts are
never sent. On Unraid, use the **User Scripts** plugin:

1. Install **User Scripts** from the Apps tab.
2. **Settings → User Scripts → Add New Script**, and name it `borgwarehouse-checks`.
3. Edit the script and paste in [`scripts/borgwarehouse-cron.sh`](scripts/borgwarehouse-cron.sh).
4. Set the schedule to **Custom**, `0 * * * *` (hourly).

The script runs the checks inside the container using the `CRONJOB_KEY` from the template, so the key isn't copied
anywhere else. If you renamed the container, change `CONTAINER=` at the top of the script.

## Single sign-on (OIDC)

Under **Show more settings**:

- `OIDC_ISSUER_URL`: your provider's issuer, e.g. `https://auth.example.com/application/o/borgwarehouse/`
  for Authentik or `https://kc.example.com/realms/home` for Keycloak.
- `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`: from the provider (confidential client).
- `OIDC_PROVIDER_NAME`: label on the login button (optional).
- Redirect URI at the provider: `<BETTER_AUTH_URL>/api/auth/callback/oidc`, e.g.
  `https://borg.example.com/api/auth/callback/oidc`. BorgWarehouse always builds it from `BETTER_AUTH_URL`, so
  scheme, host and port must match that exactly, whichever address you started from. If the provider reports a
  redirect URI mismatch, the `redirect_uri` parameter in the address bar of its error page shows what was sent.
- Start SSO logins from the `BETTER_AUTH_URL` address. Starting from another trusted address (e.g. the IP) can
  fail on the way back, because the login state cookie belongs to the address you started from.

SSO only signs in existing users. Set your BorgWarehouse account's email to the one your provider sends, sign in
with SSO, then optionally set `DISABLE_PASSWORD_LOGIN` to `true`.

GitHub, Google, Microsoft and GitLab login are also supported upstream. Add the variables with **Add another
Path, Port, Variable…** (`GITHUB_CLIENT_ID`/`GITHUB_CLIENT_SECRET`, etc.). See the
[upstream docs](https://borgwarehouse.com/docs/admin-manual/oauth-oidc/).

## Notes

- **SSH host keys** are kept in `appdata/borgwarehouse/ssh_host`. Keep that folder, otherwise clients get a host
  key changed warning after reinstalling.
- **Permissions:** the container runs as `PUID`/`PGID` (99:100 by default) and fixes the ownership of the mapped
  folders when it starts. PUID or PGID 0 (root) is refused.
- **Can't log in, `Invalid origin` in the log:** the address in your browser isn't `BETTER_AUTH_URL` or listed in
  `BETTER_AUTH_TRUSTED_ORIGINS`. Scheme, host and port must all match. After several failed attempts the login is
  also rate limited for a while; restarting the container clears that.
- **Reverse proxy:** set `BETTER_AUTH_URL` to the proxied URL. If you also use the direct `http://IP:3000`
  address, add it to `BETTER_AUTH_TRUSTED_ORIGINS`. Only the web UI goes through the proxy: Borg traffic is SSH
  on the SSH port, so forward that port on your router if clients back up from outside your network.
- **Extra storage locations** (`STORAGE_TARGETS`): add each path as a Path mapping too.
- **Notifications:** BorgWarehouse can use an [Apprise](https://github.com/caronc/apprise) API server. Run the
  Apprise container and point BorgWarehouse at it in the web UI.

## Support

Questions and help on Unraid: the [support thread](https://forums.unraid.net/topic/200915-plugin-borgwarehouse/) on the Unraid forums. Bugs in the template (defaults,
descriptions, the User Scripts script): open an [issue here](https://github.com/jamesfreeman959/unraid-borgwarehouse/issues).
Problems with BorgWarehouse itself: [upstream](https://github.com/Ravinou/borgwarehouse/issues).

## Repository layout

| Path | Purpose |
| --- | --- |
| `templates/borgwarehouse.xml` | Unraid Docker template. This is the canonical copy: Unraid fetches template updates from here (`<TemplateURL>`), and the Community Applications feed in [unraid-plugins](https://github.com/jamesfreeman959/unraid-plugins) carries an identical copy |
| `scripts/borgwarehouse-cron.sh` | User Scripts script for the scheduled checks |
| `icon.svg`, `icon.png` | Icon (BorgWarehouse's own logo, from the upstream repository) |

### Testing the template before it is in CA

Copy the template onto the flash drive, then add the container from it:

```bash
wget -O /boot/config/plugins/dockerMan/templates-user/my-BorgWarehouse.xml https://raw.githubusercontent.com/jamesfreeman959/unraid-borgwarehouse/main/templates/borgwarehouse.xml
```

Then go to **Docker → Add Container** and pick **BorgWarehouse** from the template list.

### Releasing a template change

Edit `templates/borgwarehouse.xml` here, then copy it to `templates/borgwarehouse.xml` in
[unraid-plugins](https://github.com/jamesfreeman959/unraid-plugins). That repository's **Validate** workflow fails
if the two copies differ.

## License

The template and script are MIT licensed (see [LICENSE](LICENSE)). BorgWarehouse and its logo are by
[Ravinou](https://github.com/Ravinou/borgwarehouse), under the AGPL-3.0.
