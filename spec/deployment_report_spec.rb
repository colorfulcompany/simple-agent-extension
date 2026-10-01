require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe DeploymentReport do
    def report(deployments, home: "/home/you")
      DeploymentReport.new(deployments, home: home)
    end

    it "heads each Agent and lists its extensions below" do
      lines = report({
        "opencode" => [
          ["/build/opencode/own/deep-review/agent/deep-design-reviewer.md", "/home/you/.config/opencode/agents/deep-design-reviewer.md"],
          ["/build/opencode/shared/deep-review/skill/deep-design-review", "/home/you/.agents/skills/deep-design-review"]
        ]
      }).lines

      assert {
        lines == [
          "opencode",
          "  deep-review/agent -> ~/.config/opencode/agents",
          "  deep-review/skill -> ~/.agents/skills"
        ]
      }
    end

    it "keeps the order of the deployed Agents" do
      lines = report({
        "copilot" => [["/build/copilot/own/deep-review/agent/a.agent.md", "/home/you/.copilot/agents/a.agent.md"]],
        "opencode" => [["/build/opencode/own/deep-review/agent/a.md", "/home/you/.config/opencode/agents/a.md"]]
      }).lines

      assert {
        lines == [
          "copilot",
          "  deep-review/agent -> ~/.copilot/agents",
          "opencode",
          "  deep-review/agent -> ~/.config/opencode/agents"
        ]
      }
    end

    it "reports one line for an extension that deployed several files" do
      lines = report({
        "copilot" => [
          ["/build/copilot/shared/deep-review/skill/one", "/home/you/.agents/skills/one"],
          ["/build/copilot/shared/deep-review/skill/two", "/home/you/.agents/skills/two"]
        ]
      }).lines

      assert { lines == ["copilot", "  deep-review/skill -> ~/.agents/skills"] }
    end

    it "heads an Agent that deployed nothing without any extension line" do
      assert { report({"opencode" => []}).lines == ["opencode"] }
    end

    it "leaves a destination outside home as an absolute path" do
      lines = report({
        "copilot" => [["/build/copilot/shared/deep-review/skill/deep-design-review", "/work/project/.agents/skills/deep-design-review"]]
      }).lines

      assert { lines == ["copilot", "  deep-review/skill -> /work/project/.agents/skills"] }
    end

    it "does not shorten a path that only shares a prefix with home" do
      lines = report({
        "copilot" => [["/build/copilot/shared/deep-review/skill/deep-design-review", "/home/you-backup/.agents/skills/deep-design-review"]]
      }).lines

      assert { lines == ["copilot", "  deep-review/skill -> /home/you-backup/.agents/skills"] }
    end
  end
end
