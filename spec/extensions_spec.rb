require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Extensions do
    describe ".for" do
      it "predefined type" do
        assert { Extensions.for("skill") == Extensions::Skill }
      end

      it "undefined type" do
        assert_raises(KeyError) { Extensions.for("command") }
      end
    end
  end
end
