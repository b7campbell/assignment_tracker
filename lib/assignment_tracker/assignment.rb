require 'time'
require 'colorize'

class Assignment
  attr_accessor :name, :klass, :assigned_date, :due_date, :archived, :progress, :note

  @@progress_hash = {0 => "Not Started", 1 => "Planned", 2 => "In Progress", 3 => "Finished"}

  def initialize(name, klass, assigned_date, due_date, archived, progress, note)
    @name          = name
    @klass         = klass
    @assigned_date = if due_date.is_a? String
                       Time.parse(assigned_date)
                     else
                       assigned_date
                     end

    @due_date      = if due_date.is_a? String
                       Time.parse(due_date)
                     else
                       due_date
                     end
    @archived      = archived == 1
    @progress      = @@progress_hash[progress] || raise("Invalid progress number: #{progress}")
    @note          = note
  end

  def as_cli_string
    puts '--'
    puts format_days_left
    puts '--'

    "[#{@klass.bold}] #{format_progress_tag}\n"\
    "  | #{@name.italic}\n"\
    "  | #{format_days_left} until #{format_time(@due_date).bold}\n"\
    "  | [#{progress_bar}]\n"\
    "#{@note.empty? ? '' : "  | Note: #{@note}\n"}"
  end

  def days_left
    days_between(@due_date, Time.now)
  end

  def started?
    @progress != "Not Started"
  end

  def finished?
    @progress == "Finished"
  end

  private

  def days_between(t1, t2)
    ((t1 - t2) / (3600 * 24)).round(1)
  end

  def format_days_left
    color_by_days_left "#{days_left.to_s.rjust(4, ' ')} days left"
  end

  def color_by_days_left(str) 
    if finished?
      str.green
    else
      # generic message
      if days_left > 5
        str.blue
      # start this soon
      elsif days_left > 2.5 && days_left <= 5
        str.colorize(:light_blue)
      # due date coming up and haven't started
      elsif (days_left > 1 && days_left <= 2.5) && !started?
        str.red
      # due date coming up and have started
      elsif days_left > 1 && days_left <= 2.5
        str.yellow
      # due or past due date
      elsif days_left <= 1
        str.red
      else
        raise "days_left fall through detected. Aborting..."
      end
    end
  end

  def total_days
    days_between(@due_date, @assigned_date)
  end

  def format_progress_tag
    if @progress == "Not Started"
      "Not Started".red
    elsif @progress == "Finished"
      "Finished".green
    else
      @progress.yellow
    end

  end

  def format_time(time)
    time.strftime("%l:%M%p, %a %d %b %Y")
  end

  def progress_bar
    percent_done = (1 - days_left / total_days).round(2)
    num_bars = (ProgressBarMaxChars*percent_done).round
    str = (ProgressBarChar * num_bars).ljust(ProgressBarMaxChars, ' ')

    if percent_done <= 1
      str.insert(ProgressBarMaxChars/2, "#{(percent_done * 100).round}%")
    end
    color_by_days_left str
  end
end

