require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Extensions::Skill do
    describe "#entrypoint" do
      it "uses a fixed skill entrypoint" do
        assert {
          Extensions::Skill.new(package: "deep-review", dir: ".", files: ["SKILL.md"]).entrypoint == "SKILL.md"
        }
      end
    end
  end
end
