require 'spec_helper'
describe SalorSession do
    it "should return the proper cast type" do
     SalorSession.cast(1).should == :to_i 
     SalorSession.cast("hello").should == :to_s
     SalorSession.cast(2.34).should == :to_f
    end
    it "should overload {}=" do
      SalorSession[:test] = "hello"
      SalorSession[:test].should == "hello"
    end
    it "should dump to file" do
      $IP = "127.0.0.1"
      SalorSession.dump
    end
    it "should load" do
      $IP = "127.0.0.1"
      SalorSession.load
      SalorSession[:test].should == "hello"
    end
 end
