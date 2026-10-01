module SimpleAgentExtension
  module Extensions
    EntrypointDocument = Data.define(:metadata, :body)

    # An extension that owns loading metadata from its directory.
    class Base
      # @param [String] package
      # @param [String] dir directory holding the extension, source or build
      # @param [Array<String>] files paths relative to +dir+
      def initialize(package:, dir:, files:)
        @package = package
        @dir = dir
        @files = files
      end
      attr_reader :package, :dir, :files

      # @return [Metadata] source YAML mapping
      def metadata
        metadata_loader.metadata
      end

      # @return [String]
      def type
        self.class.name.split("::").last.downcase
      end

      # The name the extension is deployed under.
      #
      # prefer metadata.yaml over document frontmatter
      #
      # @return [String]
      def name
        metadata["name"] || entrypoint_document.metadata["name"] || package
      end

      # @return [String] relative to +dir+
      def entrypoint
        raise NotImplementedError
      end

      # @return [String]
      def entrypoint_path
        File.join(dir, entrypoint)
      end

      # @return [EntrypointDocument]
      def entrypoint_document
        metadata, body = Frontmatter.parse(File.read(entrypoint_path))

        EntrypointDocument.new(metadata, body)
      end

      # @return [MetadataLoader] source YAML reader
      def metadata_loader
        @metadata_loader ||= MetadataLoader.load(dir)
      end

      # @return [Array<String>, nil] Agent names this extension is distributed
      #   to; nil when it names none and therefore reaches every Agent
      def deploy_to
        metadata_loader.deploy_to
      end

      # @param [String] agent_name
      # @return [Boolean]
      def deployable_to?(agent_name)
        names = deploy_to

        names.nil? || names.include?(agent_name)
      end
    end
  end
end
