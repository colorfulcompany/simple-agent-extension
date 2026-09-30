require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Extensions::Agent do
    def deep_review_agent(files)
      Extensions::Agent.new(package: "deep-review", dir: ".", files: files)
    end

    describe "#entrypoint" do
      it "uses the only top-level Markdown file" do
        files = ["deep-design-reviewer.md", "references/notes.md", "scripts/run.sh"]

        assert {
          deep_review_agent(files).entrypoint == "deep-design-reviewer.md"
        }
      end

      it "no file exists corresponding to the name" do
        assert_raises(AmbiguousEntrypoint) do
          deep_review_agent(["a.md", "b.md"]).entrypoint
        end
      end
    end
  end
end
