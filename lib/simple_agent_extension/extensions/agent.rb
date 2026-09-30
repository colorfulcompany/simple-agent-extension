module SimpleAgentExtension
  module Extensions
    class Agent < Base
      # Found rather than derived from the name: in the build tree the name is
      # read from this very file's frontmatter, and deriving it would close a
      # loop.
      #
      # @return [String]
      def entrypoint
        candidates = files.select { |path|
          File.dirname(path) == "." && File.extname(path) == ".md"
        }

        unless candidates.size == 1
          raise AmbiguousEntrypoint,
            "expected exactly one top level .md in #{dir}, got #{candidates.inspect}"
        end

        candidates.first
      end
    end
  end
end
