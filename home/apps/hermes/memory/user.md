# Hermes reusable user profile seed

This file is Git-managed source-of-truth for stable user preferences that should be reproducible across x250 and runrun.

- User prefers concise, direct responses.
- User prefers the assistant to execute commands when it says it will, rather than only describing steps.
- User prefers declarative, reproducible NixOS changes for system services and tools.
- User prefers Hermes configuration to be persisted through services.hermes-agent in the NixOS flake, not ad-hoc runtime edits under /var/lib/hermes.
- When the user says `~`, they mean the `run` user's home directory `/home/run`, not `/root`.
- User does not want previous conversations/sessions to be synchronized across machines.
- User does not need API keys or other secrets to be reproducible through Git.
