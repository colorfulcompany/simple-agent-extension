require "fileutils"

module SimpleAgentExtension
  # Writes one source extension to `build/<agent>/<scope>/<pkg>/<type>/` for
  # the configured Agent. It first resolves entrypoint metadata and artifact
  # scope, then writes the artifact core file and its bundled files.
  #
  # The resulting scope has these meanings:
  #
  #  [source package] -> (compile) -> shared skill/ (scope)
  #                                -> agent dir A/  (scope)
  #                                    +-- skills/  (type)
  #                                         +- <pkg>/
  #                                    +-- agents/  (type)
  #                                         +- <pkg>/
  #                                -> agent dir B/
  #
  # - `shared` is a skill with no agent-specific representation or metadata.
  # - `own` is material for one agent's configuration tree. A skill becomes
  #
  #   own when its representation or named metadata differs; an agent is
  #   always own because it has no shared destination.
  #
  # The scope is recorded in the build path so Deployer can map the artifact
  # to a destination without rereading source or reapplying these rules.
  class Compiler
    FragmentTransporter = Data.define(
      :overlaid_adaptive,
      :common_static,
      :agent_static
    )

    # @param [AgentBase] agent supplies translation, core-file, and deployment facts
    # @param [String] build_root forwarded to Collector.build
    def initialize(agent:, build_root:)
      @agent = agent
      @metadata_composer = MetadataComposer.new
      @build_root = build_root
    end

    # @param [Extensions::Base] extension
    # @return [String]
    def compile(extension)
      document = extension.entrypoint_document
      dto = fragment_transporter(
        loader: extension.metadata_loader,
        document: document,
        extension_name: extension.name
      )

      adapted_fragments = translate_for_agent(
        type: extension.type,
        overlaid_adaptive: dto.overlaid_adaptive
      )
      artifact_scope = classify_artifact_scope(
        type: extension.type,
        overlaid_adaptive: dto.overlaid_adaptive,
        adapted: adapted_fragments,
        agent_static: dto.agent_static
      )
      artifact_metadata = @metadata_composer.overlay_agent_specific(
        common: dto.common_static,
        adapted: adapted_fragments,
        agent_static: dto.agent_static
      )
      materialize_artifact(
        extension,
        body: document.body,
        metadata: artifact_metadata,
        artifact_scope: artifact_scope
      )
    end

    # A shared artifact is valid only when the Agent supports sharing,
    # adaptation leaves its metadata unchanged, and no Agent-specific static
    # metadata is configured. Common static metadata does not affect this decision because it
    # applies to every Agent.
    #
    # @param [String, Symbol] type
    # @param [Metadata] overlaid_adaptive adaptive source fragments with extension identity applied
    # @param [Metadata] adapted metadata after Agent translation
    # @param [Metadata] agent_static
    # @return [Symbol] :shared or :own
    def classify_artifact_scope(type:, overlaid_adaptive:, adapted:, agent_static:)
      return :own unless @agent.deployment.shared?(type)
      return :own unless adapted == overlaid_adaptive && agent_static.empty?

      :shared
    end

    # @param [MetadataLoader] loader
    # @param [EntrypointDocument] document
    # @param [String] extension_name
    # @return [FragmentTransporter]
    def fragment_transporter(loader:, document:, extension_name:)
      FragmentTransporter.new(
        overlaid_adaptive: overlaid_adaptive(
          adaptive: loader.adaptive,
          name: extension_name
        ),
        common_static: @metadata_composer.common_static_fragments(
          frontmatter: document.metadata,
          common_static: loader.common_static
        ),
        agent_static: loader.agent_static(@agent.name)
      )
    end

    # @param [String, Symbol] type
    # @param [Metadata] overlaid_adaptive
    # @return [Metadata]
    def translate_for_agent(type:, overlaid_adaptive:)
      fragments = overlaid_adaptive.each_with_object({}) do |(field, value), output|
        fragment =
          if @agent.can_trans_meta?(type: type, field: field)
            @agent.trans_meta(type: type, field: field, value: value)
          else
            {field => value}
          end
        output.merge!(fragment) if fragment
      end

      Metadata.from(fragments)
    end

    private

    # Overlays adaptive source fragments on extension identity before field-by-field
    # Agent processing.
    #
    # @param [Metadata] adaptive
    # @param [String] name
    # @return [Metadata]
    def overlaid_adaptive(adaptive:, name:)
      Metadata.from("name" => name).merge(adaptive)
    end

    # @param [Extensions::Base] extension
    # @param [String] body
    # @param [Metadata] metadata
    # @param [Symbol] artifact_scope
    # @return [String]
    def materialize_artifact(extension, body:, metadata:, artifact_scope:)
      dir = Collector.build(root: @build_root, agent: @agent,
        scope: artifact_scope)
        .dir(package: extension.package, type: extension.type)
      artifact_core_file = @agent.artifact_core_file(
        extension_type: extension.type,
        extension_name: extension.name,
        source_file: extension.entrypoint
      )

      FileUtils.rm_rf(dir)
      write(File.join(dir, artifact_core_file), Frontmatter.render(metadata, body))
      copy_bundled_files(extension, dir: dir, artifact_core_file: artifact_core_file)

      dir
    end

    # @param [Extensions::Base] extension
    # @param [String] dir
    # @param [String] artifact_core_file
    def copy_bundled_files(extension, dir:, artifact_core_file:)
      (extension.files - [extension.entrypoint]).each do |file|
        copy(File.join(extension.dir, file), File.join(dir, File.dirname(artifact_core_file), file))
      end
    end

    def write(path, text)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, text)
    end

    def copy(src, dest)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(src, dest)
    end
  end
end
