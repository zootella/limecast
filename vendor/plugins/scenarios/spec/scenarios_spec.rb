require File.dirname(__FILE__) + "/spec_helper"

describe "Scenario loading" do
  it "should load from configured directories" do
    Scenario.load(:empty)
    EmptyScenario
  end
  
  it "should raise Scenario::NameError when the scenario does not exist" do
    lambda { Scenario.load(:whatcha_talkin_bout) }.should raise_error(Scenario::NameError)
  end
  
  it "should allow us to add helper methods through the helpers class method" do
    klass = :empty.to_scenario
    klass.helpers do
      def hello
        "Hello World"
      end
    end
    klass.new.methods.should include('hello')
  end
end

describe "Scenario example helper methods" do
  scenario :things
  
  it "should understand namespaced models" do
    create_record "ModelModule::Model", :raking, :name => "Raking", :description => "Moving leaves around"
    models(:raking).should_not be_nil
  end
  
  it "should include pluralized record name readers" do
    things(:one).should be_kind_of(Thing)
    things(:two).name.should == "two"
  end
  
  it "should include singular record id reader" do
    thing_id(:one).should be_kind_of(Fixnum)
  end
  
  it "should include record creation methods" do
    create_record(:thing, :three, :name => "Three")
    things(:three).name.should == "Three"
  end
  
  it "should include other example helper methods" do
    create_thing("The Thing")
    things(:the_thing).name.should == "The Thing"
  end
end

describe "it uses people and things scenarios", :shared => true do
  it "should have reader helper methods for each used scenario" do
    should respond_to(:things)
    should respond_to(:people)
  end
  
  it "should allow us to use helper methods from each scenario inside an example" do
    should respond_to(:create_thing)
    should respond_to(:create_person)
  end
end

describe "A composite scenario" do
  scenario :composite
  
  it_should_behave_like "it uses people and things scenarios"
  
  it "should allow us to use helper methods scenario" do
    should respond_to(:method_from_composite_scenario)
  end
end

describe "Multiple scenarios" do
  scenario :things, :people
  
  it_should_behave_like "it uses people and things scenarios"
end

describe "A complex composite scenario" do
  scenario :complex_composite
  
  it_should_behave_like "it uses people and things scenarios"
  
  it "should have correct reader helper methods" do
    should respond_to(:places)
  end
  
  it "should allow us to use correct helper methods" do
    should respond_to(:create_place)
  end
end

describe "Overlapping scenarios" do
  scenario :composite, :things, :people
  
  it "should not cause scenarios to be loaded twice" do
    Person.find_all_by_first_name("John").size.should == 1
  end
end

describe "create_record class method" do
  scenario :empty
  
  it "should automatically set timestamps" do
    create_record :note, :first, :content => "first note"
    note = notes(:first)
    note.created_at.should be_instance_of(Time)
  end
end