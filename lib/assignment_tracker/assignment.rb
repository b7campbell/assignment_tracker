require 'time'
require 'colorize'

require_relative 'config.rb'

class Assignment
  attr_accessor :name, :klass, :assigned_date, :due_date, :archived, :progress, :note

  @@progress_hash = { NotStarted => "Not Started",
                      Planned => "Planned",
                      InProgress => "In Progress",
                      Finished => "Finished" }

  def initialize(name, klass, assigned_date, due_date, progress, archived, note)
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
    @archived      = archived == Archived
    @progress      = if [NotStarted, Planned, InProgress, Finished].include? progress
                       progress
                     else
                       raise("Invalid progress number: #{progress}")
                     end
    @note          = note
  end

  def as_cli_string
    "[#{@klass.bold}] #{format_progress_tag}\n"\
    "  | #{@name.italic}\n"\
    "  | #{format_days_left} #{format_time(@due_date).bold}\n"\
    "  | [#{progress_bar}]\n"\
    "#{@note.empty? ? '' : "  | Note: #{@note}\n"}"
  end

  def days_left
    days_between(@due_date, Time.now)
  end

  def started?
    @progress != NotStarted
  end

  def finished?
    @progress == Finished
  end

  def exclude_from_sort
    progress_bar.to_s.include? "assignments" 
  end

  private

  def days_between(t1, t2)
    ((t1 - t2) / (3600 * 24)).round(1)
  end

  def format_days_left
    if days_left <= 0
      color_by_days_left 'due date was'
    else
      color_by_days_left "#{days_left.to_s.rjust(4, ' ')} days left until"
    end
  end

  def color_by_days_left(str) 
    d = days_left
    if finished?
      str.green
    elsif d < 1.5
      str.red
    elsif d < 3
      str.yellow
    else
      p = 1 - percent_time_left 
      # generic message
      if p > 0.75
        str.blue
      # start this soon
      elsif (p > 0.55 && p <= 0.75)
        str.colorize(:light_blue)
      # due date coming up and haven't started
      elsif p > 0.25 && p <= 0.55 && !started?
        str.red
      # due date coming up and have started
      elsif p > 0.25 && p <= 0.55
        str.yellow
      # due or past due date
      elsif p <= 0.25
        str.red
      else
        raise "days_left fall through detected"
      end
    end
  end

  def total_days
    days_between(@due_date, @assigned_date)
  end

  def format_progress_tag
    case @progress
    when NotStarted
      @@progress_hash[progress].red
    when Planned
      @@progress_hash[progress].yellow
    when InProgress
      @@progress_hash[progress].yellow
    when Finished
      @@progress_hash[progress].green
    else
      raise "format_progress_tag fall through detected"
    end

  end

  def format_time(time)
    time.strftime("%l:%M%p, %a %d %b %Y")
  end

  def percent_time_left
    (1 - days_left / total_days).round(2)
  end

  def progress_bar
    percent = percent_time_left
    num_bars =
      begin
        (ProgressBarMaxChars*percent).round
      rescue FloatDomainError
        ProgressBarMaxChars
      end

    if num_bars < 0
      num_bars = 0
    end

    str = (ProgressBarChar * num_bars).ljust(ProgressBarMaxChars, ' ')

    if percent <= 1 && percent >= 0
      str.insert(ProgressBarMaxChars/2, "#{(percent * 100).round}%")
    else
      str = "    do other assignments on deck    "
    end
    color_by_days_left str
  end
end

