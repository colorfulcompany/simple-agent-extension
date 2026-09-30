module SimpleAgentExtension
  # Traverses the `<package>/<type>/` layout shared by source extensions and
  # compiled artifacts. This is the only place that knows that layout.
  class Collector
    # Source metadata is agent-independent input, before Agent-specific
    # translation. All source extensions therefore share one tree:
    #
    #   <source_root>/<package>/<type>/
    #
    # @param [String] root source package root
    # @return [Collector] source extension collection
    def self.source(root:)
      new(root: root)
    end

    # Agent-specific metadata, filenames, and scope can differ. Build artifacts
    # are partitioned by Agent before the shared package/type layout so those
    # results remain distinct:
    #
    #   <build_root>/<agent>/<scope>/<package>/<type>/
    #
    # @param [String] root build root
    # @param [AgentBase] agent selects one Agent's artifact subtree
    # @param [Symbol] scope selects that Agent's shared or own artifacts
    # @return [Collector] compiled artifact collection
    def self.build(root:, agent:, scope:)
      new(root: File.join(root, agent.name, scope.to_s))
    end

    # @param [String] root
    def initialize(root:)
      @root = root
    end
    attr_reader :root

    # Build artifacts have no `metadata.yaml` and no name to read from it, so
    # Deployer walks +dirs+ instead.
    #
    # @param [String, nil] package
    # @param [String, nil] type
    # @return [Array<Extensions::Base>]
    def extensions(package: nil, type: nil)
      dirs(package: package, type: type).map { |pkg, kind, dir|
        Extensions.for(kind).new(
          package: pkg,
          dir: dir,
          files: files(pkg, kind)
        )
      }
    end

    # @param [String, nil] package
    # @param [String, nil] type
    # @return [Array<[String, String, String]>] package, type, dir
    def dirs(package: nil, type: nil)
      Dir.glob(File.join(package || "*", type || "*", ""), base: root).map { |rel|
        pkg, kind = rel.chomp("/").split("/")
        [pkg, kind, dir(package: pkg, type: kind)]
      }.sort
    end

    # `build/<agent>/<scope>/<pkg>/<type>/` is compile's write target too, so
    # Compiler asks here rather than assembling the path itself.
    #
    # @param [String] package
    # @param [String] type
    # @return [String]
    def dir(package:, type:)
      File.join(root, package, type)
    end

    private

    # @param [String] package
    # @param [String] type
    # @return [Array<String>] paths relative to +dir+
    def files(package, type)
      base = dir(package: package, type: type)

      Dir.glob("**/*", base: base)
        .select { |path| File.file?(File.join(base, path)) }
        .reject { |path| path == MetadataLoader::FILENAME }
        .sort
    end
  end
end
