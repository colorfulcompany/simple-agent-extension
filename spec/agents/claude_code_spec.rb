require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension::Agents
  describe ClaudeCode do
    describe ClaudeCode::MetadataTranslator do
      describe "#translate" do
        describe "when the type is agent" do
          describe "with allow, ask, and deny permissions" do
            it "lists allowed and asked tools in tools and denied tools in disallowedTools" do
              assert {
                ClaudeCode::MetadataTranslator.new.translate(
                  type: :agent,
                  field: "permissions",
                  value: {"read" => "allow", "edit" => "ask", "bash" => "deny"}
                ) == {"tools" => "Read, Edit", "disallowedTools" => "Bash"}
              }
            end
          end

          describe "without deny permissions" do
            it "omits disallowedTools" do
              assert {
                ClaudeCode::MetadataTranslator.new.translate(
                  type: :agent,
                  field: "permissions",
                  value: {"read" => "allow"}
                ) == {"tools" => "Read"}
              }
            end
          end
        end

        describe "when the type is skill" do
          describe "with allow, ask, and deny permissions" do
            it "lists allowed tools in allowed-tools and denied tools in disallowed-tools" do
              assert {
                ClaudeCode::MetadataTranslator.new.translate(
                  type: :skill,
                  field: "permissions",
                  value: {"read" => "allow", "edit" => "ask", "bash" => "deny"}
                ) == {"allowed-tools" => "Read", "disallowed-tools" => "Bash"}
              }
            end
          end

          describe "with only ask permissions" do
            it "returns no fields" do
              assert {
                ClaudeCode::MetadataTranslator.new.translate(
                  type: :skill,
                  field: "permissions",
                  value: {"edit" => "ask"}
                ) == {}
              }
            end
          end
        end

        describe "with known lowercase tool names" do
          it "returns Claude Code tool names" do
            assert {
              ClaudeCode::MetadataTranslator.new.translate(
                type: :agent,
                field: "permissions",
                value: {
                  "read" => "allow",
                  "edit" => "allow",
                  "write" => "allow",
                  "bash" => "allow",
                  "glob" => "allow",
                  "grep" => "allow",
                  "webfetch" => "allow",
                  "websearch" => "allow",
                  "task" => "allow",
                  "todowrite" => "allow"
                }
              ) == {"tools" => "Read, Edit, Write, Bash, Glob, Grep, WebFetch, WebSearch, Agent, TodoWrite"}
            }
          end
        end

        describe "with Claude Code spellings and unknown tool names" do
          it "returns them unchanged" do
            assert {
              ClaudeCode::MetadataTranslator.new.translate(
                type: :agent,
                field: "permissions",
                value: {"Read" => "allow", "mcp__server__tool" => "allow"}
              ) == {"tools" => "Read, mcp__server__tool"}
            }
          end
        end
      end
    end

    describe "#artifact_core_file" do
      describe "when the type is agent" do
        it "returns a plain markdown filename" do
          assert {
            ClaudeCode.new.artifact_core_file(
              extension_type: :agent,
              extension_name: "review",
              source_file: "ignored.md"
            ) == "review.md"
          }
        end
      end
    end

    describe "#config_dir" do
      describe "without a configured directory" do
        it "returns the Claude Code configuration directory" do
          assert {
            ClaudeCode.new.config_dir == File.expand_path("~/.claude")
          }
        end
      end
    end

    describe "#skill_shared?" do
      it "returns false" do
        assert { ClaudeCode.new.skill_shared? == false }
      end
    end
  end
end
