module SimpleAgentExtension
  # Test-specific pass-through Agent. It lives outside the Agents namespace so
  # production registry discovery cannot include it.
  class TestingAgent < AgentBase
    NAME = "testing".freeze

    class MetadataTranslator < ::SimpleAgentExtension::AgentProperty::MetadataTranslator
      define_translation type: :skill, field: "permissions" do |permissions|
        {"allowed-tools" => permissions.filter_map { |tool, action| tool if action == "allow" }.join(" ")}
      end

      define_translation type: :agent, field: "permissions" do |permissions|
        {"tools" => permissions.filter_map { |tool, action| tool if action == "allow" }}
      end
    end

    # @return [String]
    def default_config_dir
      File.expand_path("~/.config/testing")
    end

    # @return [String]
    def agent_dir
      File.join(config_dir, "agents")
    end

    def agent_core_file(extension_name:, source_file: _source_file)
      "#{extension_name}.md"
    end
  end

  class TestingAgentWithoutSharedSkills < TestingAgent
    def skill_shared? = false
  end

  # Declares both product facts a subclass may optionally carry. There is no
  # counterpart declaring only one of them; nothing depends on that case yet.
  class TestingFullDescribedAgent < TestingAgent
    NAME = "described".freeze
    DESCRIPTION = "An example coding agent".freeze
    HOMEPAGE = "https://example.test".freeze
  end

  # Declares neither, and inherits both from its superclass.
  class TestingAgentInheritingDescription < TestingFullDescribedAgent
    NAME = "inheriting".freeze
  end
end
