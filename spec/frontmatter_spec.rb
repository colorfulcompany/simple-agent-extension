require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Frontmatter do
    describe ".parse" do
      it "parses frontmatter and body" do
        data, body = Frontmatter.parse("---\nname: x\n---\nbody\n")

        assert { data.is_a?(Metadata) }
        assert { [data, body] == [{"name" => "x"}, "body\n"] }
      end

      it "treats text without frontmatter as the body" do
        data, body = Frontmatter.parse("no frontmatter\n---\nnot one either\n")

        assert { [data, body] == [Metadata.new, "no frontmatter\n---\nnot one either\n"] }
      end

      it "parses empty frontmatter" do
        data, body = Frontmatter.parse("---\n---\nbody\n")

        assert { [data, body] == [Metadata.new, "body\n"] }
      end

      it "leaves a horizontal rule in the body untouched" do
        _, body = Frontmatter.parse("---\nname: x\n---\n# title\n\n---\n\ntail\n")

        assert { body == "# title\n\n---\n\ntail\n" }
      end

      it "rejects non-mapping frontmatter" do
        assert_raises(Frontmatter::InvalidFrontmatter) do
          Frontmatter.parse("---\n- a\n- b\n---\nbody\n")
        end
      end
    end

    describe ".render" do
      it "renders frontmatter in the canonical format" do
        text = Frontmatter.render(Metadata.from("name" => "x"), "body\n")

        assert { text == "---\nname: x\n---\nbody\n" }
      end

      it "omits empty frontmatter when rendering" do
        assert { Frontmatter.render(Metadata.new, "body\n") == "body\n" }
      end
    end
  end
end
