require_relative '../spec_helper'
require 'date'
require 'timecop'

describe Todo::Task do
  it 'should recognise priorities' do
    task = Todo::Task.new "(A) Hello world!"
    task.priority.should == "A"
  end

  it 'should only recognise priorities at the start of a task' do
    task = Todo::Task.new "Hello, world! (A)"
    task.priority.should == nil
  end

  it 'should recognise contexts' do
    task = Todo::Task.new "Hello, world! @test"
    task.contexts.should == ["@test"]
  end

  it 'should recognise multiple contexts' do
    task = Todo::Task.new "Hello, world! @test @test2"
    task.contexts.should == ["@test", "@test2"]
  end

  it 'should recognise projects' do
    task = Todo::Task.new "Hello, world! +test"
    task.projects.should == ["+test"]
  end

  it 'should recognise multiple projects' do
    task = Todo::Task.new "Hello, world! +test +test2"
    task.projects.should == ["+test", "+test2"]
  end

  it 'should retain the original task' do
    task = Todo::Task.new "(A) This is an awesome task, yo. +winning"
    task.orig.should == "(A) This is an awesome task, yo. +winning"
  end

  it 'should be able to get just the text, no contexts etc.' do
    task = Todo::Task.new "x (B) 2012-03-04 This is a sweet task. @context +project"
    task.text.should == "This is a sweet task."
  end

  it 'should be comparable' do
    task1 = Todo::Task.new "(A) Top priority, y'all!"
    task2 = Todo::Task.new "(B) Not quite so high."

    assertion = task1 > task2
    assertion.should == true
  end

  it 'should be comparable to task without priority' do
    task1 = Todo::Task.new "Top priority, y'all!"
    task2 = Todo::Task.new "(B) Not quite so high."

    assertion = task1 < task2
    assertion.should == true
  end

  it 'should be able to compare two tasks without priority' do
    task1 = Todo::Task.new "Top priority, y'all!"
    task2 = Todo::Task.new "Not quite so high."

    assertion = task1 == task2
    assertion.should == true
  end

  it 'should be able to recognise dates' do
    task = Todo::Task.new "(C) 2012-03-04 This has a date!"
    task.date.should == Date.parse("4th March 2012")
  end

  it 'should be able to recognise dates without priority' do
    task = Todo::Task.new "2012-03-04 This has a date!"
    task.date.should == Date.parse("4th March 2012")
  end

  it 'should return nil if no date is present' do
    task = Todo::Task.new "No date!"
    task.date.should be_nil
  end

  it 'should not recognise malformed dates' do
    task = Todo::Task.new "03-04-2012 This has a malformed date!"
    task.date.should be_nil
  end

  it 'should be able to tell if the task is overdue' do
    task = Todo::Task.new((Date.today - 1).to_s + " This task is overdue!")
    task.overdue?.should be_true
  end

	it 'should return false if task is not overdue' do
		task = Todo::Task.new((Date.today + 1).to_s + " This task is due soon.")
		task.overdue?.should be_false
	end

  it 'should return nil on overdue? if there is no date' do
    task = Todo::Task.new "No date!"
    task.overdue?.should be_nil
  end

  it 'should return nil on ridiculous date data' do
    task = Todo::Task.new "2012-56-99 This has a malformed date!"
    task.date.should be_nil
  end

  it 'should be able to recognise completed tasks' do
    task = Todo::Task.new "x 2012-12-08 This is done!"
    task.done?.should be_true
  end

  it 'should not recognize incomplete tasks as done' do
    task = Todo::Task.new "2012-12-08 This ain't done!"
    task.done?.should be_false
  end

  it 'should be completable' do
    task = Todo::Task.new "2012-12-08 This ain't done!"
    task.do!
    task.done?.should be_true
  end

  it 'should be marked as incomplete' do
    task = Todo::Task.new "x 2012-12-08 This is done!"
    task.undo!
    task.done?.should be_false
  end

  it 'should be toggable' do
    task = Todo::Task.new "2012-12-08 This ain't done!"
    task.toggle!
    task.done?.should be_true
    task.toggle!
    task.done?.should be_false
  end

  it 'should be able to recognise completion dates' do
    task = Todo::Task.new "x 2012-12-08 This is done!"
    task.date.should == Date.parse("8th December 2012")
  end

  it 'should remove the priority when calling Task#do!' do
    task = Todo::Task.new "(A) Task"
    task.do!
    task.priority.should be_nil
  end

  it 'should reset to the original priority when calling Task#undo!' do
    task = Todo::Task.new "(A) Task"
    task.do!
    task.undo!
    task.priority.should == "A"
  end

  it 'should set the current completion dates when calling Task#do!' do
    task = Todo::Task.new "2012-12-08 Task"
    Timecop.freeze(2013, 12, 8) do
      task.do!
      task.date.should == Date.parse("8th December 2013")
    end
  end

  it 'should reset to the original due date when calling Task#undo!' do
    task = Todo::Task.new "2012-12-08 Task"
    Timecop.freeze(2013, 12, 8) do
      task.do!
      task.undo!
      task.date.should == Date.parse("8th December 2012")
    end
  end

  it 'should manage dates when calling Task#toggle!' do
    task = Todo::Task.new "2012-12-08 This ain't done!"
    Timecop.freeze(2013, 12, 8) do
      task.toggle!
      task.date.should == Date.parse("8th December 2013")
      task.toggle!
      task.date.should == Date.parse("8th December 2012")
    end
  end

  it 'should convert to a string' do
    task = Todo::Task.new "(A) 2012-12-08 My task @test +test2"
    task.to_s.should == "(A) 2012-12-08 My task @test +test2"
  end
  
  it 'should keep track of the original string after changing the task' do
    task = Todo::Task.new "(A) 2012-12-08 My task @test +test2"
    Timecop.freeze(2013, 12, 8) do
      task.do!
      task.orig.should == "(A) 2012-12-08 My task @test +test2"
    end
  end
  
  it 'should show be modifiable' do
    task = Todo::Task.new "2012-12-08 My task @test +test2"
    task.projects.clear
    task.contexts << ["@test3"]
    Timecop.freeze(2013, 12, 8) do
      task.do!
      task.to_s.should == "x 2013-12-08 My task @test @test3"
    end
  end
end
