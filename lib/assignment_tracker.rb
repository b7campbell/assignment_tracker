require 'date'
require 'tty'

require_relative 'assignment_tracker/config.rb'
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
				when :archive_assignment
          archive_assignment
				when :delete_assignment
          delete_assignment
				when :list_active_assignments
          list_assignments
          TerminalHelper.wait
				when :list_all_assignments
          list_all_assignments
          TerminalHelper.wait
				when :quit
					quit
					break
        when :update_assignment
          update_assignment
				end
			end 
		end

		private

		@@choices = [
									{ key: 'a', name: 'add new assignment',            value: :add_assignment          },
									{ key: 'r', name: 'archive assignment',            value: :archive_assignment      },
									{ key: 'd', name: 'delete assignment',             value: :delete_assignment       },
									{ key: 'l', name: 'print all open assignments',    value: :list_active_assignments },
									{ key: 'p', name: 'print all assignments',         value: :list_all_assignments    },
									{ key: 'q', name: 'close program',                 value: :quit                    },
									{ key: 'u', name: 'update assignment',             value: :update_assignment       }
								]
	 
    def select_yes_or_no(message)
      @prompt.select(message) do |menu|
        menu.choice 'no',  false
        menu.choice 'yes', true
      end
    end

		def add_assignment
			return unless select_yes_or_no('Continue?')
			loop do
				@db.add_assignment(build_assignment)
				break unless select_yes_or_no('Continue adding entries?')
			end
		end

		def archive_assignment
			loop do
        colval = ask_for_column_and_value('select which parameter to search by: ')
        break if colval == :cancel

        as = @db.select_assignments_by_colval(*colval)

        if as.nil? || as.empty?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        a = select_open_assignment(as)

        if a.nil?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        TerminalHelper.redraw_terminal
        TerminalHelper.newline
        puts a.as_cli_string
        TerminalHelper.newline

        if select_yes_or_no('Archive this entry?')
          @db.archive_assignment(a)
        end
        if select_yes_or_no('Return to main menu?')
          break
        end
			end
		end

    def delete_assignment
      loop do
        colval = ask_for_column_and_value('select which parameter to search by: ')
        break if colval == :cancel

        as = @db.select_assignments_by_colval(*colval)

        if as.nil? || as.empty?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        a = select_an_assignment(as)

        if a.nil?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        TerminalHelper.redraw_terminal
        TerminalHelper.newline
        puts a.as_cli_string
        TerminalHelper.newline

        if select_yes_or_no('Delete this entry?')
          @db.delete_assignment(a)
        end
        if select_yes_or_no('Return to main menu?')
          break
        end
      end
    end

    def list_assignments
      TerminalHelper.newline
      puts @db.list_assignments
      TerminalHelper.newline
    end

    def list_all_assignments
      TerminalHelper.newline
      puts @db.list_all_assignments
      TerminalHelper.newline
    end

		def quit
			puts "Quitting..."
			TerminalHelper.exit_routine
		end

    def update_assignment
      loop do
        colval = ask_for_column_and_value('select which parameter to search by: ')
        break if colval == :cancel

        as = @db.select_assignments_by_colval(*colval)

        if as.nil? || as.empty?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        a = select_an_assignment(as)

        if a.nil?
          puts "No matches found."
          TerminalHelper.newline
          next
        end

        TerminalHelper.redraw_terminal
        TerminalHelper.newline
        puts a.as_cli_string
        TerminalHelper.newline

        puts 'pick column to update'
        col, val = ask_for_column_and_value('select which parameter to edit: ')

        if val
          puts "will update assignment's '#{col}' to '#{val}'"
        end

        if val && select_yes_or_no('Update this entry?')
          @db.update_assignment(a, col, val)
        end
        if select_yes_or_no('Return to main menu?')
          break
        end
      end
    end

    #
    # Build Assignment Object
    #

    def ask_for_name
      @prompt.ask("assignment name: ") do |answer|
        answer.required true
        answer.validate /^\S.*$/
      end.chomp
    end

    def ask_for_klass
      @prompt.ask("class: ") do |answer|
        answer.validate /^[A-Za-z]+[ ]\d{1,3}[A-Za-z]{,2}$/
      end.chomp.upcase
    end

    def ask_for_date(str)
      # TODO: handle leap days
      date = nil
      year = Time.now.year
      loop do
        date = @prompt.ask("#{str} date: ") do |answer|
          answer.default "#{Time.now.month}/#{Time.now.day}"
        end
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
      @prompt.select("select most accurate progress tag: ") do |menu|
        menu.choice 'Not Started', NotStarted
        menu.choice 'Planned',     Planned
        menu.choice 'In Progress', InProgress
        menu.choice 'Finished',    Finished
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
          menu.choice 'archived?',     :archive
          menu.choice 'cancel',        :cancel
        end
    end

    def build_assignment
      name          = ask_for_name
      klass         = ask_for_klass
      assigned_date = ask_for_date('assigned')
      due_date      = ask_for_date('due')
      archived      = 0
      progress      = ask_for_progress
      note          = ask_for_note

      a = Assignment.new(name=name, klass=klass, assigned_date=assigned_date,\
                             due_date=due_date, progress=progress, archived=archived, note=note)

      loop do
        TerminalHelper.redraw_terminal
        TerminalHelper.newline
        puts a.as_cli_string
        TerminalHelper.newline

        break if select_yes_or_no("Everything look right?")
        a = edit_param(a)
      end
      a
    end

    def edit_param(a)
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
      when :archive
        a.archived = select_yes_or_no("Should assignment be archived?")
      when :note
        a.note = ask_for_note
      when :cancel
      else
        @prompt.warn("Unknown error in param selection occured")
      end
      a
    end

    #
    # functions for removal
    #
    def ask_for_column_and_value(msg)
      col = @prompt.select(msg) do |menu|
        menu.choice 'name', 'name'
        menu.choice 'class', 'klass'
        menu.choice 'assigned date', 'adate'
        menu.choice 'due date', 'ddate'
        menu.choice 'archived', 'archived'
        menu.choice 'progress', 'progress'
        menu.choice 'note', 'note'
        menu.choice 'cancel', :cancel
      end

      return :cancel if col == :cancel

      val = @prompt.ask("give value for column #{col}: ")
      return [col, val]
    end

    def select_open_assignment(as)
      id = 0
      TerminalHelper.newline
      as.reject { |a| a.archived }.each do |a|
        puts "Id: #{id}"
        puts a.as_cli_string
        TerminalHelper.newline

        id += 1
      end

      return nil if id.zero? 

      index = nil
      loop do
        index = @prompt.ask("by id, select which row to work with") do |answer|
          answer.validate /^\d+$/
          answer.convert  :int
        end

        if index.between?(0,id-1)
          break
        else
          @prompt.warn("id chosen out of bounds")
        end
      end
      return as[index]
    end

    def select_an_assignment(as)
      id = 0
      TerminalHelper.newline
      as.each do |a|
        puts "Id: #{id}"
        puts a.as_cli_string
        TerminalHelper.newline

        id += 1
      end

      return nil if id.zero?

      index = nil
      loop do
        index = @prompt.ask("by id, select which row to work with") do |answer|
          answer.validate /^\d+$/
          answer.convert  :int
        end

        if index.between?(0,id-1)
          break
        else
          @prompt.warn("id chosen out of bounds")
        end
      end
      return as[index]
    end

	end
	# ===========================
	# Build Object and Enter Loop
	# ===========================
	APP_CLI.new.run
 
end
