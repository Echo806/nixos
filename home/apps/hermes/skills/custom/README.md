# Custom Hermes skills

Put Git-managed custom Hermes skills here.

Expected layout:

custom/
  example-skill/
    SKILL.md
    references/
    scripts/
    templates/
    assets/

This directory is copied declaratively into /var/lib/hermes/.hermes/skills/custom by system/services/hermes-agent.nix.
