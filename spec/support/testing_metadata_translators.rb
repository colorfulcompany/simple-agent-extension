module SimpleAgentExtension
  class TestingMetadataTranslatorOverrideValueOnly < AgentProperty::MetadataTranslator
    define_translation type: :agent, field: "model" do |value|
      {"model" => "provider/model-name"}
    end
  end

  class TestingMetadataTranslatorOverrideFieldAndValue < AgentProperty::MetadataTranslator
    define_translation type: :agent, field: "permissions" do |value|
      {"tools" => value.select { |tool, perm| perm.to_s == "allow" }.keys}
    end
  end

  class TestingMetadataTranslatorReturnNil < AgentProperty::MetadataTranslator
    define_translation type: :agent, field: "name" do |value|
      nil
    end
  end

  class TestingMetadataTranslatorStub
    def can_translate?(...) = false

    def translate(...)
      raise "unexpected translate"
    end
  end
end
