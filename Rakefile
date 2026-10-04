# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "yard/rake/yardoc_task"
require "standard/rake"

Minitest::TestTask.create(:spec) do |t|
  t.libs.concat(%w[lib spec])
  t.test_globs = [File.join(__dir__, "spec/**/*_spec.rb")]
end

namespace :geminabox do
  desc "Start a loopback-only local Geminabox server"
  task :start do
    data = ENV.fetch("GEMINABOX_DATA", File.join(__dir__, "tmp/geminabox"))
    port = ENV.fetch("GEMINABOX_PORT", "9292")

    exec(
      {"GEMINABOX_DATA" => data},
      "bundle", "exec", "rackup",
      "--server", "puma",
      "--host", "127.0.0.1",
      "--port", port,
      File.join(__dir__, "config/geminabox.ru")
    )
  end

  desc "Build and publish the local package to Geminabox"
  task :push do
    artifact = File.join(__dir__, "tmp", "simple-agent-extension.gem")
    url = ENV.fetch("GEMINABOX_URL", "http://127.0.0.1:9292")

    mkdir_p File.dirname(artifact)
    sh "gem", "build", "simple-agent-extension.gemspec", "--output", artifact
    sh "bundle", "exec", "gem", "inabox", "--overwrite", "--host", url, artifact
  end
end

YARD::Rake::YardocTask.new do |t|
end

task default: :spec
