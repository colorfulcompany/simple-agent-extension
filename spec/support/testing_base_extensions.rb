module SimpleAgentExtension
  module TestingBase
    class Skill < Extensions::Base
      #
      # always used as basename
      #
      def entrypoint
        "SKILL.md"
      end
    end

    class WithBothMetadataAndFrontmatterName < Extensions::Base
      def metadata
        Metadata.from("name" => "metadata-name")
      end

      def entrypoint_document
        Extensions::EntrypointDocument.new(Metadata.from("name" => "frontmatter-name"), "")
      end
    end

    class WithMetadataNameOnly < Extensions::Base
      def metadata
        Metadata.from("name" => "metadata-name")
      end

      def entrypoint_document
        Extensions::EntrypointDocument.new(Metadata.new, "")
      end
    end

    class WithFrontmatterNameOnly < Extensions::Base
      def metadata
        Metadata.new
      end

      def entrypoint_document
        Extensions::EntrypointDocument.new(Metadata.from("name" => "frontmatter-name"), "")
      end
    end

    class WithDeployTo < Extensions::Base
      def metadata_loader
        MetadataLoader.new(Metadata.from("deploy_to" => ["copilot", "opencode"]))
      end
    end

    class WithoutDeployTo < Extensions::Base
      def metadata_loader
        MetadataLoader.new(Metadata.new)
      end
    end

    class NoMetadataNoFrontmatter < Extensions::Base
      def metadata
        Metadata.new
      end

      def entrypoint_document
        Extensions::EntrypointDocument.new(Metadata.new, "")
      end
    end
  end
end
