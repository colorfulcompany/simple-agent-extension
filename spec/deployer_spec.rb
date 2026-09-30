require "spec_helper"
require "simple_agent_extension"
require "fixture"

module SimpleAgentExtension
  describe Deployer do
    def configured_copilot(workspace, installed: true)
      home = File.join(workspace, "home")
      config_dir = File.join(home, "copilot")
      FileUtils.mkdir_p(config_dir) if installed

      Agents::Copilot.new(
        config_dir: config_dir,
        shared_skill_dir: File.join(home, "shared/skills")
      )
    end

    describe "#deploy" do
      after { @workspace&.close }

      describe "when a shared skill artifact is built" do
        before do
          @workspace = Fixture.build_workspace("shared-skill")
          @agent = configured_copilot(@workspace.root)
          @deployer = Deployer.new(agent: @agent, build_root: @workspace.build_root)
          @shared_skill_source = File.join(@workspace.build_root, "copilot/shared/metadata-free/skill/metadata-free")
          @shared_skill_destination = File.join(@agent.shared_skill_dir, "metadata-free")
        end

        it "returns its source/destination mapping" do
          assert { @deployer.deploy == [[@shared_skill_source, @shared_skill_destination]] }
        end
      end

      describe "when a destination already exists" do
        before do
          @workspace = Fixture.build_workspace("stale-agent-v1")
          @agent = configured_copilot(@workspace.root)
          @deployer = Deployer.new(agent: @agent, build_root: @workspace.build_root)
        end

        it "replaces its contents with the returned source" do
          previous_source, deployed_destination = @deployer.deploy.fetch(0)
          previous_content = File.read(previous_source)
          Fixture.copy("build-trees/stale-agent-v2", to: @workspace.build_root)
          replacement_source, replacement_destination = @deployer.deploy.fetch(0)

          assert { replacement_destination == deployed_destination }
          assert { File.read(replacement_source) != previous_content }
          assert { File.read(replacement_destination) == File.read(replacement_source) }
        end
      end

      describe "when an own agent artifact is built" do
        before do
          @workspace = Fixture.build_workspace("agent-only")
          @agent = configured_copilot(@workspace.root)
          @deployer = Deployer.new(agent: @agent, build_root: @workspace.build_root)
          @own_agent_source = File.join(@workspace.build_root, "copilot/own/metadata-free/agent/metadata-free.agent.md")
          @own_agent_destination = File.join(@agent.agent_dir, "metadata-free.agent.md")
        end

        it "returns its source/destination mapping" do
          assert { @deployer.deploy == [[@own_agent_source, @own_agent_destination]] }
        end
      end

      describe "when the Agent config directory does not exist" do
        before do
          @workspace = Fixture.build_workspace("agent-only")
          @agent = configured_copilot(@workspace.root, installed: false)
          @deployer = Deployer.new(agent: @agent, build_root: @workspace.build_root)
          @source = File.join(@workspace.build_root, "copilot/own/metadata-free/agent/metadata-free.agent.md")
          @destination = File.join(@agent.agent_dir, "metadata-free.agent.md")
        end

        it "warns and skips deployment without creating destinations" do
          _stdout, stderr = capture_io { @mappings = @deployer.deploy }

          assert {
            [
              @mappings,
              stderr,
              File.exist?(@agent.config_dir),
              File.exist?(@agent.shared_skill_dir)
            ] == [
              [],
              "skipped deployment for uninstalled agent: copilot (#{@agent.config_dir})\n",
              false,
              false
            ]
          }
        end

        it "deploys when forced" do
          mappings = @deployer.deploy(force: true)

          assert { mappings == [[@source, @destination]] }
          assert { File.exist?(@destination) }
        end
      end
    end
  end
end
