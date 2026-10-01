require "yaml"

module SimpleAgentExtension
  # Reads `<pkg>/<type>/metadata.yaml` into Metadata. The YAML file is an input,
  # not a distributable (collector.rb excludes it from +files+).
  #
  # The source YAML includes sections that classify metadata fragments. This
  # reader exposes adaptive, common static, and Agent-specific static fragment
  # collections without defining their field vocabulary.
  class MetadataLoader
    FILENAME = "metadata.yaml".freeze

    # @param [String] dir
    # @return [MetadataLoader] empty when +metadata.yaml+ is absent, never nil
    def self.load(dir)
      path = File.join(dir, FILENAME)
      return new(Metadata.new) unless File.exist?(path)

      new(Metadata.from(YAML.safe_load(File.read(path)) || {})) # rubocop:disable Style/YAMLFileRead
    end

    # @param [Metadata] metadata source YAML mapping
    def initialize(metadata)
      @metadata = metadata
    end
    attr_reader :metadata

    # Names the Agents this extension is distributed to. It is a selection
    # constraint, not metadata carried into an artifact, so it stays outside
    # the adaptive and static sections.
    #
    # @return [Array<String>, nil] nil when the extension names no target,
    #   which means every configured Agent
    def deploy_to
      value = metadata["deploy_to"]
      return nil if value.nil?

      Array(value).map(&:to_s)
    end

    # @return [Metadata] adaptive source fragments
    def adaptive
      section("adaptive")
    end

    # @return [Metadata] common static fragments
    def common_static
      Metadata.from(section("static")["common"] || {})
    end

    # @param [String] agent_name
    # @return [Metadata] Agent-specific static fragments
    def agent_static(agent_name)
      Metadata.from(section("static").dig("agents", agent_name) || {})
    end

    private

    def section(name)
      Metadata.from(metadata[name] || {})
    end
  end
end
