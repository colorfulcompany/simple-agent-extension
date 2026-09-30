require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Metadata do
    describe ".from" do
      it "creates metadata from a Hash" do
        metadata = Metadata.from("name" => "deep-design-reviewer")

        assert { metadata.is_a? Metadata }
        assert { metadata["name"] == "deep-design-reviewer" }
      end
    end

    it "is retained by merge" do
      assert { Metadata.new.merge("name" => "deep-design-reviewer").is_a? Metadata }
    end
  end
end
