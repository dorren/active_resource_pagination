require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Hash do
  describe "#partition" do
    it "should partition" do
      h1, h2 = {'a' => 1, 'b' => 2, 'c' => 10, 'd' => 20}.partition{|k, v| v >= 10}
      h1.should == {'c' => 10, 'd' => 20}
      h2.should == {'a' => 1, 'b' => 2}
    end
  end
end