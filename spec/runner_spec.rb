require "spec_helper"
require "simple_agent_extension"
require "fixture"
require "support/testing_agent"

module SimpleAgentExtension
  describe Runner do
    after { @workspace&.close }

    def runner(workspace, agent_registry: AgentRegistry.default)
      Runner.new(
        source_root: workspace.source_root,
        build_root: workspace.build_root,
        agent_registry: agent_registry
      )
    end

    describe "#packages" do
      before do
        @workspace = Fixture.valid_workspace
        @runner = runner(@workspace)
      end

      it "lists each source package once" do
        assert {
          @runner.packages == [
            "agent-raw-override",
            "bundled-skill",
            "entrypoint-frontmatter",
            "metadata-free",
            "metadata-name-and-common-raw",
            "translated-permissions"
          ]
        }
      end
    end

    describe "#agents" do
      before do
        @workspace = Fixture.valid_workspace
      end

      it "reports the name, description, and homepage of every configured Agent" do
        registry = AgentRegistry.new([TestingFullDescribedAgent.new])

        assert {
          runner(@workspace, agent_registry: registry).agents == [
            {
              name: "described",
              description: "An example coding agent",
              homepage: "https://example.test"
            }
          ]
        }
      end

      it "reports no description or homepage for an Agent that declares neither" do
        registry = AgentRegistry.new([TestingAgent.new])

        assert {
          runner(@workspace, agent_registry: registry).agents ==
            [{name: "testing", description: nil, homepage: nil}]
        }
      end

      it "keeps the order of the configured registry" do
        registry = AgentRegistry.new([TestingFullDescribedAgent.new, TestingAgent.new])

        assert {
          runner(@workspace, agent_registry: registry).agents.map { |agent| agent[:name] } ==
            ["described", "testing"]
        }
      end
    end

    describe "#build" do
      describe "with the valid package fixture" do
        before do
          @workspace = Fixture.valid_workspace
          @runner = runner(@workspace)
        end

        it "builds artifacts for both targets when no target is selected" do
          directories = @runner.build.map { |dir| dir.delete_prefix("#{@workspace.root}/") }

          assert {
            [
              directories.include?("build/copilot/shared/metadata-free/skill"),
              directories.include?("build/opencode/own/translated-permissions/agent")
            ] == [true, true]
          }
        end

        it "rejects an unknown selected agent through the registry" do
          assert_raises(UnknownAgentName) { @runner.build(agent: "missing") }
        end
      end

      describe "with the invalid package fixture" do
        before do
          @workspace = Fixture.invalid_workspace
          @runner = runner(@workspace)
        end

        it "rejects an invalid package catalog" do
          assert_raises(KeyError) { @runner.build }
        end
      end
    end

    describe "#deploy" do
      before do
        @workspace = Fixture.valid_workspace
        @home = File.join(@workspace.root, "home")
        @copilot = Agents::Copilot.new(
          config_dir: File.join(@home, "copilot"),
          shared_skill_dir: File.join(@home, "copilot-shared/skills")
        )
        @opencode = Agents::OpenCode.new(
          config_dir: File.join(@home, "opencode"),
          shared_skill_dir: File.join(@home, "opencode-shared/skills")
        )
        FileUtils.mkdir_p(@copilot.config_dir)
        FileUtils.mkdir_p(@opencode.config_dir)
        @runner = runner(@workspace, agent_registry: AgentRegistry.new([@copilot, @opencode]))
        @runner.build
      end

      def destinations(deployed, agent_name)
        deployed.fetch(agent_name).map { |_source, destination| destination }
      end

      it "keys the result by Agent name in registry order" do
        assert { @runner.deploy.keys == ["copilot", "opencode"] }
      end

      it "reports only that Agent's destinations under its key" do
        deployed = @runner.deploy

        assert {
          destinations(deployed, "opencode").all? { |path|
            path.start_with?(@opencode.config_dir) || path.start_with?(@opencode.shared_skill_dir)
          }
        }
      end
    end

    describe "#install" do
      before do
        @workspace = Fixture.valid_workspace
        @home = File.join(@workspace.root, "home")
        @copilot = Agents::Copilot.new(
          config_dir: File.join(@home, "copilot"),
          shared_skill_dir: File.join(@home, "copilot-shared/skills")
        )
        @opencode = Agents::OpenCode.new(
          config_dir: File.join(@home, "opencode"),
          shared_skill_dir: File.join(@home, "opencode-shared/skills")
        )
        FileUtils.mkdir_p(@copilot.config_dir)
        FileUtils.mkdir_p(@opencode.config_dir)
        @runner = runner(@workspace, agent_registry: AgentRegistry.new([@copilot, @opencode]))
      end

      it "builds and deploys artifacts for both targets when no target is selected" do
        compiled, = @runner.install

        assert {
          compiled.all? { |dir| File.directory?(dir) } &&
            [
              "copilot/agents/translated-permissions.agent.md",
              "opencode/agents/translated-permissions.md",
              "copilot-shared/skills/bundled-skill/references/checklist.md",
              "opencode-shared/skills/bundled-skill/references/checklist.md"
            ].all? { |path| File.exist?(File.join(@home, path)) }
        }
      end

      it "builds and deploys only Copilot artifacts when Copilot is selected" do
        compiled, = @runner.install(agent: "copilot")

        assert {
          compiled.all? { |dir| dir.include?("/copilot/") } &&
            File.exist?(File.join(@home, "copilot-shared/skills/metadata-free/SKILL.md")) &&
            File.exist?(File.join(@home, "copilot/agents/metadata-free.agent.md")) &&
            !File.exist?(File.join(@home, "opencode/agents/metadata-free.md")) &&
            !File.exist?(File.join(@home, "opencode-shared/skills/metadata-free/SKILL.md"))
        }
      end

      it "skips an uninstalled Agent while building artifacts for all targets" do
        FileUtils.rm_rf(@opencode.config_dir)
        _stdout, stderr = capture_io { @compiled, _deployed = @runner.install }

        assert {
          @compiled.any? { |dir| dir.include?("/copilot/") } &&
            @compiled.any? { |dir| dir.include?("/opencode/") } &&
            File.exist?(File.join(@home, "copilot/agents/metadata-free.agent.md")) &&
            !File.exist?(@opencode.config_dir) &&
            !File.exist?(@opencode.shared_skill_dir) &&
            stderr == "skipped deployment for uninstalled agent: opencode (#{@opencode.config_dir})\n"
        }
      end

      it "passes force through install to deploy an uninstalled Agent" do
        FileUtils.rm_rf(@opencode.config_dir)
        _stdout, stderr = capture_io { @runner.install(force: true) }

        assert {
          stderr.empty? && File.exist?(File.join(@home, "opencode/agents/metadata-free.md"))
        }
      end
    end
  end
end
