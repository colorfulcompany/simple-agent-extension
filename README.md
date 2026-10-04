# SimpleAgentExtension

`simple-agent-extension` compiles each single source package into Agent-specific artifacts and can deploy a fresh build to locally installed Agents.

## Installation

Requires Ruby 3.3 or later (not needed beforehand when running with `rvx`, which provides Ruby itself).

Add the gem to your Gemfile:

```ruby
# Gemfile
group :development do
  gem "simple-agent-extension"
end
```

```sh
bundle install
```

Then run the CLI through Bundler:

```sh
bundle exec simple-agent-extension packages
```

Or run it without a Gemfile with [rv](https://github.com/spinel-coop/rv)'s `rvx`, which installs the gem on first use:

```sh
rvx simple-agent-extension packages
```

## Usage

### Defining a package

A **package** is an author-owned unit under the source root. It holds one or more **extensions**, one per extension type:

```text
packages/
└── awesome-package/          # package
    ├── skill/                # extension (type: skill)
    │   ├── SKILL.md          # entrypoint
    │   ├── metadata.yaml     # compiler input, never distributed
    │   └── references/       # bundled as-is
    └── agent/                # extension (type: agent)
        ├── awesome-worker.md
        └── metadata.yaml
```

- Supported extension types are `skill` and `agent`. Either may stand alone; a package does not need both.
- A `skill` entrypoint is always `SKILL.md`.
- An `agent` entrypoint is the single top-level `*.md` file. Anything other than exactly one is an error.
- Every other file under an extension directory is copied into the artifact unchanged, nested directories included. `metadata.yaml` is the one exception.

### Extension metadata

`metadata.yaml` belongs to one extension. It sits beside that extension's entrypoint and is optional.

```yaml
name: awesome-worker

deploy_to:
  - opencode

adaptive:
  permissions:
    read: allow
    edit: ask

static:
  common:
    description: Short summary the Agent uses to decide when to load this extension.
  agents:
    opencode:
      mode: subagent
```

| Key | Meaning |
|---|---|
| `name` | Extension identity: the name the artifact is deployed under. |
| `deploy_to` | Agent names this extension is distributed to. Omitting the key distributes to every configured Agent. |
| `adaptive` | Source fragments whose artifact representation the selected Agent decides. An Agent that has a rule for the field rewrites it; a field with no rule passes through unchanged. |
| `static.common` | Written to every Agent's artifact without adaptation. |
| `static.agents.<agent>` | Written only to that Agent's artifact, without adaptation. |

`adaptive` does not mean dynamic. The value is fixed in the file; the key declares that the artifact representation belongs to the Agent rather than to the author.

#### Distribution targets

`deploy_to` limits which Agents an extension reaches.

- No build artifact is produced for an Agent the extension does not name.
- An extension carrying `deploy_to` is never written to the shared directory. That directory is read by every Agent, so sharing would undo the limit.

#### Name resolution

The extension identity is resolved in this order, later winning:

```text
package directory name
  < entrypoint frontmatter `name`
  < metadata.yaml top-level `name`
```

#### Metadata precedence

Artifact frontmatter is composed in this order, later winning:

```text
entrypoint frontmatter
  < static.common
  < Agent-specific adapted fragments (from `adaptive`)
  < static.agents.<agent>
```

#### Adaptation across Agents

One `adaptive` fragment becomes different artifact metadata per Agent. The `permissions` fragment above compiles to:

| Agent | Artifact metadata |
|---|---|
| `claude` | agent: `tools: Read, Edit`; skill: `allowed-tools: Read` |
| `copilot` | `tools: [read]` |
| `opencode` | `permission: {read: allow, edit: ask}` |

`claude` maps known lowercase tool names such as `read` and `webfetch` to Claude Code's names (`Read`, `WebFetch`) and passes any other name through unchanged. `deny` becomes `disallowedTools` on an agent and `disallowed-tools` on a skill. An agent's `tools` lists both `allow` and `ask` tools, because Claude Code's `tools` limits which tools exist rather than pre-approving them.

A skill whose metadata is left unchanged by adaptation and carries no Agent-specific static fragments is written once to the shared skill directory. Otherwise it is written into that Agent's own configuration tree ( written with Ruby ). An agent extension is always Agent-specific. `claude` does not read the shared skill directory, so its skills are always written to `~/.claude/skills`.

### Commands

`-h` / `--help` lists every command with a one-line summary.

snapshot as below:

```sh
simple-agent-extension packages
simple-agent-extension build
simple-agent-extension deploy
simple-agent-extension agents
```

All commands resolve `--source-root` from `./packages` and `--build-root` from `./build` by default. Either root may be outside the repository.

```sh
simple-agent-extension deploy \
  --source-root /work/extensions/packages \
  --build-root /work/extensions/build \
  --agent opencode
```

`--agent NAME` is repeatable, matching the list shape of `deploy_to`. Without it, every configured Agent is targeted. Unlike `deploy_to`, a name no configured Agent answers to stops the command.

```sh
simple-agent-extension build --agent copilot --agent opencode
```

`--agent` narrows which Agents a run operates on. It does not declare distribution, so it does not change an artifact's scope.

`--force` is valid only with `deploy`. It creates deployment directories for an Agent whose configuration root is not already present.

### External Agent registrations

Pass `--agent-dir DIRECTORY` one or more times to load trusted local Agent definitions.

- Only direct `*.rb` children are loaded; subdirectories are ignored.
- Each file must be self-contained. A registration cannot define an Agent that refers to an Agent defined in a sibling file, such as a subclass of one. Load order is an implementation detail, so such a definition is unsupported even when a particular filename ordering happens to make it load.
- Each loaded file must add a new `SimpleAgentExtension::Agents::*` subclass of `SimpleAgentExtension::AgentBase`.
- Duplicate Agent names and registration failures stop the command before build or deploy begins.

Agent registrations are executable Ruby and are not sandboxed. Do not load untrusted directories.

## Development

### Repository tasks

`Rakefile` is for development tasks:

```sh
bundle exec rake spec
bundle exec standardrb
```

### Local gem source

Geminabox is a development-only dependency that serves the public Compact Index API locally. It is for package verification and does not become a runtime dependency of `simple-agent-extension`.

Start the loopback-only server in one terminal:

```sh
bundle exec rake geminabox:start
```

In another terminal, build and publish the local package:

```sh
bundle exec rake geminabox:push
```

Then install it from the local source in an isolated gem home if desired:

```sh
gem_home="$(mktemp -d)"
GEM_HOME="$gem_home" GEM_PATH="$gem_home" \
  gem install --clear-sources --source http://127.0.0.1:9292 \
  --no-document simple-agent-extension
```

Set `GEMINABOX_DATA`, `GEMINABOX_PORT`, or `GEMINABOX_URL` to use a non-default temporary location or port.
