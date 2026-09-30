module SimpleAgentExtension
  # Applies precedence rules to metadata fragment collections.
  class MetadataComposer
    # Owns the precedence rule between frontmatter metadata and
    # `metadata.yaml`'s `static.common` section.
    #
    # Both sources contribute metadata without entering Agent translation.
    # `static.common` is the stronger source and therefore wins on conflicting
    # fields. Keeping this operation explicit prevents that source-boundary
    # rule from disappearing into a final render-time merge.
    #
    # @param [Metadata] frontmatter parsed from the entrypoint
    # @param [Metadata] common_static `metadata.yaml` common static metadata
    # @return [Metadata] common static fragments
    def common_static_fragments(frontmatter:, common_static:)
      frontmatter.merge(common_static)
    end

    # Overlays Agent-specific fragments on common fragments. Adapted fragments
    # win over common fragments; static fragments win last.
    #
    # @param [Metadata] common common static fragments
    # @param [Metadata] adapted Agent-specific adapted fragments
    # @param [Metadata] agent_static `metadata.yaml` Agent-specific static fragments
    # @return [Metadata] metadata ready for artifact materialization
    def overlay_agent_specific(common:, adapted:, agent_static:)
      Metadata.from(common)
        .merge(adapted)
        .merge(agent_static)
    end
  end
end
