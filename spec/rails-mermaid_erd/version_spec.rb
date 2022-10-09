require "spec_helper"

describe RailsMermaidErd::VERSION do
  context "Whern get version" do
    it "Return the correct string as the version" do
      expect { Gem::Version.new(RailsMermaidErd::VERSION) }.not_to raise_error
    end
  end
end
