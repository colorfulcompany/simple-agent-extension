module SimpleAgentExtension
  module AgentProperty
    # Converts one source metadata field into Agent metadata fragments. Callers
    # retain ownership of field traversal and fragment composition.
    class MetadataTranslator
      class UnknownTypeAndFieldCombination < Error; end

      # Class methods for defining translations
      class << self
        # @param [String, Symbol] type ( `skill' or `agent' or ... )
        # @param [String, Symbol] field ( metadata's field name )
        # @param [#call] transform
        # @yieldparam value [Object] value of the declared source metadata field
        # @yieldreturn [Hash, nil] Agent metadata fragment collection, or field omission
        def define_translation(type:, field:, &transform)
          raise ArgumentError, "define_translation requires a block" unless transform

          translations[[type.to_sym, field.to_s]] = transform
        end

        # @return [Hash{[String, String] => #call}]
        def translations
          @translations ||= {}
        end
      end

      # @return [Hash{[String, String] => #call}]
      def translations
        self.class.translations
      end

      # @param [String] type
      # @param [String] field
      # @return [Boolean] whether a translation rule is registered
      def can_translate?(type:, field:)
        self.class.translations.key?([type.to_sym, field.to_s])
      end

      # translation entrypoint
      #
      # @param [String, Symbol] type
      # @param [String, Symbol] field
      # @param [Object] value
      # @return [Hash, nil] Agent metadata fragment collection, or omission
      # @raise [UnknownTypeAndFieldCombination] when no translation is registered for type and field
      def translate(type:, field:, value:)
        transform = self.class.translations.fetch([type.to_sym, field.to_s]) {
          raise UnknownTypeAndFieldCombination.new("Unknown combination of type: `#{type}' and field: `#{field}'")
        }

        transform.call(value)
      end
    end
  end
end
