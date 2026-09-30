module SimpleAgentExtension
  module Agents
    class Copilot < AgentBase
      NAME = "copilot".freeze

      class MetadataTranslator < ::SimpleAgentExtension::AgentProperty::MetadataTranslator
        define_translation type: :skill, field: "permissions" do |permissions|
          {"tools" => permissions.filter_map { |tool, action| tool if action == "allow" }}
        end

        define_translation type: :agent, field: "permissions" do |permissions|
          {"tools" => permissions.filter_map { |tool, action| tool if action == "allow" }}
        end
      end

      def default_config_dir
        File.expand_path("~/.copilot")
      end

      # @param [String] extension_name
      # @param [String] source_file
      # @return [String] core file relative to the artifact type directory
      def agent_core_file(extension_name:, source_file: _source_file)
        "#{extension_name}.agent.md"
      end
    end
  end
end
