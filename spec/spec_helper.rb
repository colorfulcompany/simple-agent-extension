# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "minitest/power_assert"
require "power_assert/colorize"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
