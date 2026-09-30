require "spec_helper"
require "simple_agent_extension"
require "fixture"
require "support/testing_agent"

module SimpleAgentExtension
  describe TestingAgent do
    before { @testing_agent = TestingAgent.new }
    after { @testing_agent = nil }

    def with_configured_agent
      Fixture.workspace do |workspace|
        config_dir = File.join(workspace, "testing-agent")
        shared_skill_dir = File.join(workspace, "testing-shared-skills")
        agent = TestingAgent.new(config_dir: config_dir, shared_skill_dir: shared_skill_dir)

        yield agent, config_dir, shared_skill_dir
      end
    end

    it "is a test-specific Agent outside the production namespace" do
      assert {
        !Agents.constants(false).include? :TestingAgent
      }
    end

    describe "#config_dir" do
      describe "no config_dir given" do
        it "equal to default" do
          assert {
            @testing_agent.config_dir == @testing_agent.default_config_dir
          }
        end
      end
      describe "config_dir given" do
        it "override default with cwd based path" do
          agent = TestingAgent.new(config_dir: "foo")

          assert {
            agent.config_dir == File.join(Dir.pwd, "foo")
          }
        end
      end
    end

    describe "#installed?" do
      it "uses the configured config directory" do
        with_configured_agent do |agent, config_dir, _shared_skill_dir|
          before_installation = agent.installed?
          FileUtils.mkdir_p(config_dir)

          assert { [before_installation, agent.installed?] == [false, true] }
        end
      end
    end

    describe "#artifact_core_file" do
      it "exposes core files relative to the artifact type directory" do
        assert {
          @testing_agent.artifact_core_file(
            extension_type: :agent,
            extension_name: "review",
            source_file: "ignored.md"
          ) == "review.md"
        }
        assert {
          @testing_agent.artifact_core_file(
            extension_type: :skill,
            extension_name: "review",
            source_file: "SKILL.md"
          ) == "review/SKILL.md"
        }
      end

      it "is independent from configured deployment roots" do
        with_configured_agent do |agent, _config_dir, _shared_skill_dir|
          default_agent = TestingAgent.new

          assert {
            agent.artifact_core_file(
              extension_type: :agent,
              extension_name: "review",
              source_file: "ignored.md"
            ) == default_agent.artifact_core_file(
              extension_type: :agent,
              extension_name: "review",
              source_file: "ignored.md"
            )
          }
          assert {
            agent.deployment.destination(:agent, :own) !=
              default_agent.deployment.destination(:agent, :own)
          }
        end
      end
    end

    describe "metadata translation" do
      describe "#can_trans_meta?" do
        it "has rule" do
          assert { @testing_agent.can_trans_meta?(type: :agent, field: "permissions") }
        end

        it "doesn't have rule" do
          assert { !@testing_agent.can_trans_meta?(type: :agent, field: "foo") }
        end
      end

      describe "#trans_meta" do
        it "has rule" do
          assert {
            @testing_agent.trans_meta(
              type: :agent,
              field: "permissions",
              value: {"read" => "allow", "edit" => "ask"}
            ) == {"tools" => ["read"]}
          }
        end

        it "doesn't have rule" do
          assert_raises(AgentProperty::MetadataTranslator::UnknownTypeAndFieldCombination) do
            @testing_agent.trans_meta(type: :agent, field: "foo", value: "aaa")
          end
        end
      end
    end

    describe "#deployment" do
      it "maps an own agent destination" do
        with_configured_agent do |agent, config_dir, _shared_skill_dir|
          assert {
            agent.deployment.destination(:agent, :own) == File.join(config_dir, "agents")
          }
        end
      end

      it "maps own and shared skill destinations" do
        with_configured_agent do |agent, config_dir, shared_skill_dir|
          assert {
            agent.deployment.destination(:skill, :own) == File.join(config_dir, "skills")
          }
          assert {
            agent.deployment.destination(:skill, :shared) == shared_skill_dir
          }
        end
      end

      it "rejects an unsupported destination scope" do
        with_configured_agent do |agent, _config_dir, _shared_skill_dir|
          assert_raises(KeyError) { agent.deployment.destination(:agent, :shared) }
          assert_raises(KeyError) { agent.deployment.destination(:skill, :unknown) }
        end
      end

      it "reports whether a type supports shared deployment" do
        assert {
          @testing_agent.deployment.shared?(:skill)
        }
        assert {
          !@testing_agent.deployment.shared?(:agent)
        }
      end
    end
  end
end
