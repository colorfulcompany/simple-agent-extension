module SimpleAgentExtension
  module Agents
    class ClaudeCode < AgentBase
      NAME = "claude".freeze
      DESCRIPTION = "Claude Code, Anthropic's terminal coding agent".freeze
      HOMEPAGE = "https://www.anthropic.com/claude-code".freeze

      class MetadataTranslator < ::SimpleAgentExtension::AgentProperty::MetadataTranslator
        # Source tool names that differ from Claude Code's exact tool names.
        # Names not listed here pass through unchanged.
        TOOL_NAMES = {
          "read" => "Read",
          "edit" => "Edit",
          "write" => "Write",
          "bash" => "Bash",
          "glob" => "Glob",
          "grep" => "Grep",
          "webfetch" => "WebFetch",
          "websearch" => "WebSearch",
          "task" => "Agent",
          "todowrite" => "TodoWrite"
        }.freeze

        # A subagent's `tools` limits which tools it has without pre-approving
        # them, so `allow` and `ask` become indistinguishable here.
        define_translation type: :agent, field: "permissions" do |permissions|
          tool_fields(permissions, "tools" => %w[allow ask], "disallowedTools" => %w[deny])
        end

        define_translation type: :skill, field: "permissions" do |permissions|
          tool_fields(permissions, "allowed-tools" => %w[allow], "disallowed-tools" => %w[deny])
        end

        # @param [Hash{String => String}] permissions tool name to action
        # @param [Hash{String => Array<String>}] actions_by_field output field to the actions it lists
        # @return [Hash{String => String}] comma-separated tool names; empty fields are omitted
        def self.tool_fields(permissions, actions_by_field)
          actions_by_field.each_with_object({}) do |(field, actions), fields|
            tools = permissions.filter_map { |tool, action| TOOL_NAMES.fetch(tool, tool) if actions.include?(action) }
            fields[field] = tools.join(", ") unless tools.empty?
          end
        end
      end

      def skill_shared?
        false
      end

      # @return [String]
      def default_config_dir
        File.expand_path("~/.claude")
      end

      # @param [String] extension_name
      # @param [String] source_file
      # @return [String] core file relative to the artifact type directory
      def agent_core_file(extension_name:, source_file: _source_file)
        "#{extension_name}.md"
      end
    end
  end
end
