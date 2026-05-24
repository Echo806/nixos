# Hermes declarative state

This directory contains Hermes Agent state that should be reproducible across NixOS hosts.

Tracked here:
- custom skills under skills/custom/
- seed memories under memory/
- optional Hermes persona prompt in SOUL.md

Not tracked here:
- conversations/sessions
- logs/cache/runtime databases
- auth.json/OAuth tokens
- API keys and .env files

Secrets remain outside Git and are injected through services.hermes-agent.environmentFiles, currently /var/lib/hermes/env.
