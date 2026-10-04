require "yaml"

module SimpleAgentExtension
  # YAML frontmatter at the head of a markdown source.
  #
  #   ---
  #   key: value
  #   ---
  #   body
  #
  # Only the frontmatter is round-tripped through YAML; the body is carried
  # through byte for byte.
  module Frontmatter
    DELIMITER = "---".freeze
    PATTERN = /\A---\r?\n(.*?)^---[ \t]*\r?\n?/m
    # Metadata starts after the opening delimiter line.
    METADATA_START_LINE_OFFSET = 1

    class InvalidFrontmatter < Error; end

    module_function

    # @param [String] text
    # @return [Array(Metadata, String)] metadata and body
    def parse(text)
      match = PATTERN.match(text)
      return [Metadata.new, text] unless match

      data = YAML.safe_load(match[1]) || {}
      unless data.is_a?(Hash)
        raise InvalidFrontmatter, "expected a mapping, got #{data.class}"
      end

      [Metadata.from(data), match.post_match]
    end

    # @param [Metadata] metadata
    # @param [String] body
    # @return [String]
    def render(metadata, body)
      return body if metadata.nil? || metadata.empty?

      # Long values are kept on one line: some agents read frontmatter with a
      # naive line based parser rather than a YAML one.
      # YAML must receive a plain mapping; dumping Metadata itself emits a Ruby
      # class tag, which is not valid frontmatter syntax.
      "#{YAML.dump(metadata.to_h, line_width: -1)}#{DELIMITER}\n#{body}"
    end
  end
end
