module SimpleAgentExtension
  # An Agent provides metadata translation, artifact core-file placement, and
  # deployment facts for one type at a time. Compiler and Deployer consume the
  # Agent interface; they do not call the type-specific methods below directly.
  #
  # +extension_type+ selects between "skill" and "agent" through the corresponding
  # `<type>_metadata`, `<type>_core_file`, `<type>_shared?`, and
  # `<type>_destination` methods.
  class AgentBase
    class MissingMetadataTranslator < Error; end

    include AgentProperty::Skill

    # @param [String, nil] config_dir product-specific configuration directory
    # @param [String, nil] shared_skill_dir common skill destination
    def initialize(config_dir: nil, shared_skill_dir: nil)
      @config_dir = File.expand_path(config_dir) if config_dir
      @shared_skill_dir = File.expand_path(shared_skill_dir) if shared_skill_dir
    end

    # @return [String]
    def config_dir
      @config_dir || default_config_dir
    end

    # @return [Boolean] whether the Agent product is installed locally
    def installed?
      File.directory?(config_dir)
    end

    # @return [String]
    def shared_skill_dir
      @shared_skill_dir || File.expand_path("~/.agents/skills")
    end

    # @return [String]
    def name
      self.class::NAME
    end

    # @return [String, nil] one-line summary of the Agent product
    def description
      self.class::DESCRIPTION if self.class.const_defined?(:DESCRIPTION)
    end

    # @return [String, nil] official site of the Agent product
    def homepage
      self.class::HOMEPAGE if self.class.const_defined?(:HOMEPAGE)
    end

    # @param [String, Symbol] type
    # @param [String, Symbol] field
    # @return [Boolean] whether this Agent has a translation rule for the field
    def can_trans_meta?(type:, field:)
      metadata_translator&.can_translate?(type: type, field: field) || false
    end

    # @param [String, Symbol] type
    # @param [String, Symbol] field
    # @param [Object] value
    # @return [Hash, nil]
    # @raise [MissingMetadataTranslator]
    def trans_meta(type:, field:, value:)
      translator = metadata_translator
      raise MissingMetadataTranslator, "#{self.class} has no metadata translator" unless translator

      translator.translate(type: type, field: field, value: value)
    end

    # @return [AgentProperty::Deployment]
    def deployment
      @deployment ||= AgentProperty::Deployment.new(self)
    end

    # @param [String, Symbol] extension_type
    # @param [String] extension_name name the extension is deployed under
    # @param [String] source_file file relative to the source extension directory
    # @return [String] core file relative to the artifact type directory
    def artifact_core_file(extension_type:, extension_name:, source_file:)
      public_send(
        "#{extension_type}_core_file",
        extension_name: extension_name,
        source_file: source_file
      )
    end

    def agent_shared?
      false
    end

    def agent_destination(scope)
      return agent_dir if scope == :own

      raise KeyError, "agent has no #{scope} destination"
    end

    # extension type agent placed in
    #
    # @return [String]
    def agent_dir
      File.join(config_dir, "agents")
    end

    def default_config_dir
      raise NotImplementedError
    end

    private

    def metadata_translator
      translator_class = metadata_translator_class
      translator_class && (@metadata_translator ||= translator_class.new)
    end

    def metadata_translator_class
      self.class::MetadataTranslator if self.class.const_defined?(:MetadataTranslator, false)
    end
  end
end
