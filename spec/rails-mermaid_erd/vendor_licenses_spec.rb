require "spec_helper"
require "digest"
require "json"

# The gem redistributes front-end files it did not write. Their licenses ask
# for the copyright notice and the permission text to travel with them, which
# lib/templates/vendor/LICENSES.md carries. It is generated from the files, so
# it can fall behind when one is replaced; these examples catch that.
describe "vendored front-end licenses" do
  let(:root) { File.expand_path("../..", __dir__) }
  let(:vendor) { File.join(root, "lib/templates/vendor") }
  let(:licenses) { File.read(File.join(vendor, "LICENSES.md")) }

  let(:checksums) do
    File.readlines(File.join(vendor, "CHECKSUMS.txt"), chomp: true)
      .reject { |line| line.start_with?("#") || line.strip.empty? }
      .to_h { |line| line.split(/\s+/, 2).reverse }
  end

  it "lists the same SHA-256 for each file as CHECKSUMS.txt, when the files were replaced without regenerating the list" do
    listed = licenses.scan(/^\| `([^`]+)` \| `([0-9a-f]{64})` \|/).to_h

    expect(listed).to eq(checksums),
      "LICENSES.md was generated from different files than CHECKSUMS.txt names; " \
      "run `node script/licenses/generate.mjs`"
  end

  it "has a CHECKSUMS.txt that matches the vendored files" do
    actual = checksums.keys.to_h { |file| [file, Digest::SHA256.file(File.join(vendor, file)).hexdigest] }

    expect(actual).to eq(checksums)
  end

  it "names the versions the license list is generated for, as the refresh table does" do
    bundles = JSON.parse(File.read(File.join(root, "script/licenses/bundles.json")))
    readme = File.read(File.join(vendor, "README.md"))

    expect(readme).to include("mermaid@#{bundles["mermaid"]["version"]}/")
    expect(readme).to include("/vue/#{bundles["vue"]["version"]}/")
  end

  it "lists the packages of every bundled file with a license" do
    entries = licenses.scan(/^- \*\*(.+?)\*\* (\S+) — (\S+)/)

    expect(entries.size).to be > 70
    expect(entries.map(&:first)).to include("mermaid", "d3", "dompurify", "vue", "tailwindcss", "heroicons")
    expect(entries.map(&:last).uniq).to include("MIT", "ISC", "BSD-3-Clause", "Apache-2.0")
  end

  it "takes DOMPurify under the Apache License, as the list says" do
    expect(licenses).to match(/\*\*dompurify\*\* \S+ — Apache-2\.0 \(this package is MPL-2\.0 OR Apache-2\.0;/)
  end

  it "has no GPL-family license in the list" do
    expect(licenses).not_to match(/— \(?A?L?GPL/i)
  end

  it "includes the text of every license the list names, when ISC, BSD-3-Clause and Apache-2.0 packages are bundled" do
    expect(licenses).to include("Permission to use, copy, modify, and/or distribute this software for any purpose")
    expect(licenses).to include("Redistributions of source code must retain the above copyright notice")
    expect(licenses).to include("Apache License\n")
    expect(licenses).to include("Permission is hereby granted, free of charge")
  end

  it "can be embedded in an HTML comment" do
    ["-->", "--!>", "<!--", "</script"].each do |bad|
      expect(licenses).not_to include(bad)
      expect(File.read(File.join(root, "LICENSE"))).not_to include(bad)
    end
  end

  describe "the gem's own license" do
    let(:gemspec) { Gem::Specification.load(File.join(root, "rails-mermaid_erd.gemspec")) }

    it "is one file that names the copyright holder, when the gem is built" do
      expect(File).not_to exist(File.join(root, "MIT-LICENSE"))
      expect(File.read(File.join(root, "LICENSE"))).to match(/^Copyright \(c\) \d{4} \S+/)
    end

    it "ships LICENSE and the third-party list" do
      expect(gemspec.files).to include("LICENSE", "lib/templates/vendor/LICENSES.md")
      expect(gemspec.files).not_to include("MIT-LICENSE")
    end
  end
end
