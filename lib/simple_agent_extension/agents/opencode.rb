module SimpleAgentExtension
  module Agents
    class OpenCode < AgentBase
      NAME = "opencode".freeze
      DESCRIPTION = "OpenCode, an open source terminal coding agent".freeze
      HOMEPAGE = "https://opencode.ai".freeze

      class MetadataTranslator < ::SimpleAgentExtension::AgentProperty::MetadataTranslator
        define_translation type: :skill, field: "permissions" do |permissions|
          {"permission" => permissions}
        end

        define_translation type: :agent, field: "name" do |_name|
          nil
        end

        define_translation type: :agent, field: "permissions" do |permissions|
          {"permission" => permissions}
        end
      end

      # @return [String]
      def default_config_dir
        File.join(File.expand_path("~/.config"), "opencode")
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
