require "spec_helper"
require "simple_agent_extension"
require "fixture"
require "support/testing_agent"

module SimpleAgentExtension
  describe AgentRegistry do
    describe ".default" do
      before { @default_registry = AgentRegistry.default }
      after { @default_registry = nil }

      it "#all is filled as array" do
        assert {
          @default_registry.all.is_a? Array
        }
      end
      it "#all return array of AgentBase instance" do
        assert {
          @default_registry.all.all? { |e| e.is_a? AgentBase }
        }
      end
    end

    describe ".agent_classes" do
      it "subclass of AgentBase" do
        assert {
          AgentRegistry.agent_classes.all? { |e| e < AgentBase }
        }
      end
    end

    describe ".options_by_agent" do
      it "canonicalizes Agent names and initializer option keys" do
        assert {
          AgentRegistry.options_by_agent(
            opencode: {"config_dir" => "configured"}
          ) == {"opencode" => {config_dir: "configured"}}
        }
      end

      it "rejects names duplicated after normalization" do
        error = assert_raises(DuplicatedAgentConfigurationName) do
          AgentRegistry.options_by_agent("opencode" => {}, :opencode => {})
        end

        assert {
          error.message == "duplicate agent configuration: opencode"
        }
      end
    end

    describe ".configure" do
      it "uses the configured Agent destinations" do
        Fixture.workspace do |workspace|
          config_dir = File.join(workspace, "opencode")
          shared_skill_dir = File.join(workspace, "shared-skills")
          registry = AgentRegistry.configure(
            opencode: {config_dir: config_dir, shared_skill_dir: shared_skill_dir}
          )

          assert {
            registry.fetch(:opencode).config_dir == config_dir
          }
          assert {
            registry.fetch(:opencode).shared_skill_dir == shared_skill_dir
          }
        end
      end

      it "keeps omitted Agent destinations at their defaults" do
        default = AgentRegistry.default
        configured = AgentRegistry.configure(opencode: {config_dir: "configured"})

        assert {
          default.fetch(:copilot).config_dir == configured.fetch(:copilot).config_dir
        }
      end

      it "rejects an override for an unknown Agent" do
        error = assert_raises(UnknownAgentName) { AgentRegistry.configure(missing: {}) }

        assert {
          error.message == "unknown agent: missing"
        }
      end
    end

    describe "#initialize" do
      it "rejects duplicate configured names" do
        error = assert_raises(DuplicatedAgentName) do
          AgentRegistry.new([TestingAgent.new, TestingAgent.new])
        end

        assert {
          error.message == "duplicate agent: testing"
        }
      end
    end

    describe "instance methods" do
      before {
        @testing_agent = TestingAgent.new
        @testing_registry = AgentRegistry.new([@testing_agent])
      }
      after {
        @testing_agent = nil
        @testing_registry = nil
      }

      describe "#all" do
        it "returns configured Agents" do
          assert {
            @testing_registry.all == [@testing_agent]
          }
        end
      end

      describe "#each" do
        it "enumerates configured Agents" do
          yielded = []
          @testing_registry.each { |a|
            yielded << a
          }

          assert {
            yielded == [@testing_agent]
          }
        end
      end

      describe "#fetch" do
        it "returns the configured Agent" do
          assert {
            @testing_registry.fetch(:testing) == @testing_agent
          }
        end

        it "rejects an unknown name" do
          error = assert_raises(UnknownAgentName) do
            @testing_registry.fetch(:missing)
          end

          assert {
            error.message == "unknown agent: missing"
          }
        end
      end

      describe "#include?" do
        it "reports configured and missing names" do
          assert {
            @testing_registry.include?(:testing)
          }
          assert {
            !@testing_registry.include?(:missing)
          }
        end
      end
    end
  end
end
