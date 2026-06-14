# Security Policy

## Supported versions

Garmigotchi is a Connect IQ watch app. Security fixes are applied to the latest
release on the `main` branch.

## Reporting a vulnerability

If you discover a security issue, please report it privately rather than opening
a public issue:

- Use GitHub's **[Report a vulnerability](../../security/advisories/new)** (Security → Advisories), or
- Email the maintainer at **infantrykiller@gmail.com**

Please include steps to reproduce and the affected device/SDK version. We'll
acknowledge your report and work on a fix as quickly as we reasonably can.

## Scope notes

Garmigotchi runs entirely on the watch. It reads on-device sensor data (steps and
heart rate) to drive gameplay and stores its state with the Connect IQ
`Application.Storage` API. It does **not** transmit personal or sensitive data off
the device. The `developer_key.der` signing key is never committed to the
repository (it is git-ignored); keep yours private.
