# Agent skills for Infer

This directory contains [Agent Skills](https://agentskills.io) that teach AI coding agents how to
use Infer. Each subdirectory is one skill: a `SKILL.md` file with instructions, and the reference
files it points to.

| Skill | What it does |
| ----- | ------------ |
| [`infer`](infer/SKILL.md) | Runs Infer on a project to find bugs and security vulnerabilities, and triages the results. |

## Installing a skill

Copy or link the skill's directory into the directory where your agent looks for skills. For
[Claude Code](https://code.claude.com/docs/en/skills):

```sh
# for all your projects
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/infer" ~/.claude/skills/infer

# or for a single project, from that project's root
mkdir -p .claude/skills
cp -r <path to infer>/skills/infer .claude/skills/infer
```

Other agents that support the Agent Skills format read skills from their own directories; see
their documentation, and the [list of compatible agents](https://agentskills.io/clients.md).

The skills expect `infer` to be installed and on the `PATH`; see [INSTALL.md](../INSTALL.md).
