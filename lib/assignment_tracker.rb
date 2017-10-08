require 'date'
require 'tty'

require_relative 'assignment_tracker/db.rb'
require_relative 'assignment_tracker/terminal.rb'

module AssignmentTracker

	# ===================================
	# APP Command Line Interface
	# ===================================

	class APP_CLI

		def initialize
			TerminalHelper.clear_terminal
  
			@db 	  = DB.new
			@prompt = TTY::Prompt.new
			@pager  = TTY::Pager.new width: TERM_WIDTH
		end

		def run
			loop do
				TerminalHelper.redraw_terminal

				case @prompt.expand(' > Choose a command: ', @@choices)
				when :add_assignment
          add_assignment
				when :print
          print_assignments
          TerminalHelper.wait
				when :quit
					quit
					break
				end
			end 
		end

		private

		@@choices = [
									{ key: 'a', name: 'add new assignment',            value: :add_assignment    },
									{ key: 'p', name: 'print all open assignments',    value: :print             },
									{ key: 'q', name: 'close program?',                value: :quit              }
								]
	 
		def user_guess
			@prompt.ask("Enter approximate number of additions or hit return: ") do |answer|
				answer.default  '1'
				answer.required false
				answer.validate /^\d\d?$/
				answer.convert  :int
			end
		end

    def select_yes_or_no(message)
      @prompt.select(message) do |menu|
        menu.choice 'no',  false
        menu.choice 'yes', true
      end
    end

		def add_assignment
			number_of_times_to_skip_prompt = user_guess - 1
			if number_of_times_to_skip_prompt < 0
				@prompt.warn('Aborting add command. Return to root menu')
				return
			end

			loop do
				@db.add_assignment(build_assignment)

				if number_of_times_to_skip_prompt.zero?
					break unless select_yes_or_no('Continue adding entries?')
				else
					number_of_times_to_skip_prompt = number_of_times_to_skip_prompt - 1
				end
			end
		end

    #
    # Build Assignment Object
    #

    def ask_for_name
      @prompt.ask("assignment name: ").chomp
    end

    def ask_for_klass
      @prompt.ask("class: ") do |answer|
        answer.validate /^[A-Za-z]+[ ]\d{1,3}[A-Za-z]{,2}$/
      end.chomp.upcase
    end

    def read_in_date(str)
      # TODO: handle leap days
      date = nil
      year = Time.now.year
      loop do
        date = @prompt.ask("#{str} date: ")
        valid = Date.strptime(date, "%m/%d") rescue false

        if valid
          break
        else
          @prompt.warn("invalid date")
        end
      end

      # TODO: consider a 'late add method' since here, all dates here are assumed to be next year
      if 'due' == str
        if 0 > (Date.strptime(date, "%m/%d").yday - Time.now.yday)
          year = Time.now.year + 1
        end
      end

      month,day = date.split('/')

      time = ask_for_time
      Time.parse("#{year}-#{month.rjust(2, '0')}-#{day.rjust(2, '0')} #{time}")
    end

    def ask_for_time
      @prompt.ask("time: ") do |answer|
        answer.default '9:00am'
				answer.validate /^(1[0-2]|[1-9]):[0-5][0-9](am|pm)?$/
			end
    end

    def ask_for_progress
      @prompt.ask("progress (1. Not Started, 2. Planned, 3. In Progress, 4. Finished) : ") do |answer|
        answer.validate /^[1-4]$/
        answer.convert  :int
      end
    end

    def ask_for_note
      @prompt.ask("note: ") do |answer|
        answer.default ''
        answer.required false
        answer.convert  :string
      end.chomp
    end

    def ask_which_param_to_edit
        @prompt.select("Edit which parameter: ") do |menu|
          menu.choice 'name',          :name
          menu.choice 'class',         :klass
          menu.choice 'assigned date', :assigned
          menu.choice 'due date',      :due_date
          menu.choice 'progress',      :progress
          menu.choice 'note',          :note
          menu.choice 'cancel',        :cancel
        end
    end

    def build_assignment
      name          = ask_for_name
      klass         = ask_for_klass
      assigned_date = read_in_date('assigned')
      due_date      = read_in_date('due')
      archived      = 0
      progress      = ask_for_progress
      note          = ask_for_note

      a = Assignment.new(name=name, klass=klass, assigned_date=assigned_date,\
                             due_date=due_date, archived=archived, progress=progress, note=note)

      loop do
        TerminalHelper.redraw_terminal
        TerminalHelper.newline
        puts a.as_cli_string
        TerminalHelper.newline

        # TODO: chase out missing progress bar bug
        puts a.assigned_date
        puts a.due_date
        puts a.days_left

        break if select_yes_or_no("Everything look right?")

        param = ask_which_param_to_edit

        case param
        when :name
          a.name = ask_for_name
        when :klass
          a.klass = ask_for_klass
        when :assigned
          a.assigned_date = read_in_date('assigned')
        when :due_date
          a.due_date = read_in_date('due')
        when :progress
          a.progress = ask_for_progress
        when :note
          a.note = ask_for_note
        when :cancel
          break
        else
          @prompt.warn("Unknown error in param selection occured")
        end
      end
    end

=begin
		def remove_entry
			index = @prompt.ask( "Remove which item? [ 0 is abort ]" ) do |answer|
				answer.default  '0'
				answer.required false
				answer.validate /\d+$/
				answer.convert  :int
			end

			if index.zero?
				@prompt.warn( 'Aborting remove command. Return to root menu')
				sleep 1
				return 
			end
			
			removed = @ri.remove_entry(index - 1)  
			puts "Removed: #{removed}"
		end
=end

    def print_assignments
      TerminalHelper.newline
      puts @db.list_assignments
      TerminalHelper.newline
    end

		def quit
			puts "Quitting..."
			TerminalHelper.exit_routine
		end
=begin
		def commit_changes_to_file
			if select_yes_or_no( 'Save Changes?')
				@ri.write_itemlist_to_file
			else
				@prompt.warn '  Print Aborted'
			end
		end
=end
	end
	# ===========================
	# Build Object and Enter Loop
	# ===========================
	APP_CLI.new.run
 
end
