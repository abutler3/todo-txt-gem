require 'date'

module Todo
  class Task
    include Comparable

    # The regular expression used to match contexts.
    def self.contexts_regex
       /(?:\s+|^)@\w+/
    end

    # The regex used to match projects.
    def self.projects_regex
       /(?:\s+|^)\+\w+/
    end

    # The regex used to match priorities.
    def self.priotity_regex
      /^\([A-Za-z]\)\s+/
    end

    # The regex used to match dates.
    def self.date_regex
      /(?:\s+|^)([0-9]{4}-[0-9]{2}-[0-9]{2})/
    end

    # The regex used to match completion.
    def self.done_regex
      /^x\s+/
    end

    # Creates a new task. The argument that you pass in must be a string.
    def initialize task
      @orig = task
      @priority, @date = orig_priority, orig_date
      @done = !(orig =~ self.class.done_regex).nil?
      @contexts ||= orig.scan(self.class.contexts_regex).map { |item| item.strip }
      @projects ||= orig.scan(self.class.projects_regex).map { |item| item.strip }
    end
    
    # Returns the original content of the task.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) @context +project Hello!"
    #   task.orig #=> "(A) @context +project Hello!"
    attr_reader :orig

    # Returns the priority, if any.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) Some task."
    #   task.priority #=> "A"
    #
    #   task = Todo::Task.new "Some task."
    #   task.priority #=> nil
    attr_reader :priority

    # Returns an array of all the @context annotations.
    #
    # Example:
    #
    #   task = Todo:Task.new "(A) @context Testing!"
    #   task.context #=> ["@context"]
    attr_reader :contexts

    # Returns an array of all the +project annotations.
    #
    # Example:
    #
    #   task = Todo:Task.new "(A) +test Testing!"
    #   task.projects #=> ["+test"]
    attr_reader :projects

    # Gets just the text content of the todo, without the priority, contexts
    # and projects annotations.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) @test Testing!"
    #   task.text #=> "Testing!"
    def text
      @text ||= orig.
        gsub(self.class.done_regex, '').
        gsub(self.class.date_regex, '').
        gsub(self.class.priotity_regex, '').
        gsub(self.class.contexts_regex, '').
        gsub(self.class.projects_regex, '').
        strip
    end

    # Returns the date present in the task.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-03-04 Task."
    #   task.date
    #   #=> <Date: 2012-03-04 (4911981/2,0,2299161)>
    #
    # Dates _must_ be in the YYYY-MM-DD format as specified in the todo.txt
    # format. Dates in any other format will be classed as malformed and this
    # method will return nil.
    def date
      @date
    end

    # Checks whether or not this task is overdue by comparing the task date to
    # the current date.
    #
    # If there is no date specified for this task, this method returns nil.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-03-04 Task."
    #   task.overdue?
    #   #=> true
    def overdue?
      return nil if date.nil?
      date < Date.today
    end

    # Returns if the task is done.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 Task."
    #   task.done?
    #   #=> true
    #
    #   task = Todo::Task.new "Task."
    #   task.done?
    #   #=> false
    def done?
      @done
    end

    # Completes the task on the current date.
    #
    # Example:
    #
    #   task = Todo::Task.new "2012-12-08 Task."
    #   task.done?
    #   #=> false
    #
    #   task.do!
    #   task.done?
    #   #=> true
    #   task.date
    #   #=> # the current date
    def do!
      @date = Date.today
      @priority = nil
      @done = true
    end

    # Marks the task as incomplete and resets its original due date.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 Task."
    #   task.done?
    #   #=> true
    #
    #   task.undo!
    #   task.done?
    #   #=> false
    #   task.date
    #   #=> # <Date: 2012-03-04 (4911981/2,0,2299161)>
    def undo!
      @date = orig_date
      @priority = orig_priority
      @done = false
    end

    # Toggles the task from complete to incomplete or vice versa.
    #
    # Example:
    #
    #   task = Todo::Task.new "x 2012-12-08 Task."
    #   task.done?
    #   #=> true
    #
    #   task.toggle!
    #   task.done?
    #   #=> false
    #
    #   task.toggle!
    #   task.done?
    #   #=> true
    def toggle!
      done? ? undo! : do!
    end
    
    # Returns this task as a string.
    #
    # Example:
    #
    #   task = Todo::Task.new "(A) 2012-12-08 Task"
    #   task.to_s
    #   #=> "(A) 2012-12-08 Task"
    def to_s
      priority_string = priority ? "(#{priority}) " : ""
      done_string = done? ? "x " : ""
      date_string = date ? "#{date} " : ""
      contexts_string = contexts.empty? ? "" : " #{contexts.join ' '}"
      projects_string = projects.empty? ? "" : " #{projects.join ' '}"
      "#{done_string}#{priority_string}#{date_string}#{text}#{contexts_string}#{projects_string}"
    end
    
    # Compares the priorities of two tasks.
    #
    # Example:
    #
    #   task1 = Todo::Task.new "(A) Priority A."
    #   task2 = Todo::Task.new "(B) Priority B."
    #
    #   task1 > task2
    #   # => true
    #
    #   task1 == task2
    #   # => false
    #
    #   task2 > task1
    #   # => false
    def <=> other_task
      if self.priority.nil? and other_task.priority.nil?
        0
      elsif other_task.priority.nil?
        1
      elsif self.priority.nil?
        -1
      else
        other_task.priority <=> self.priority
      end
    end

    private

    def orig_priority
      orig =~ self.class.priotity_regex ? orig[1] : nil
    end

    def orig_date
      begin
        return Date.parse(orig) if orig =~ self.class.date_regex
      rescue; end
      nil
    end
  end
end
