require 'sqlite3'

require_relative 'assignment.rb'
require_relative 'config.rb'

class DB
  def initialize 
  end

  # excludes archived, low priority assignments
  def list_assignments
    assignments = []
    sqlite_cmd("SELECT * FROM #{PrimaryTable};").each do |params|
      assignment = Assignment.new(*params)
      if !assignment.archived && (assignment.days_left < 7)
        assignments.push(assignment)
      end
    end

    assignments.reject { |assignment| assignment.exclude_from_sort }. \
                sort   { |x,y| x.days_left <=> y.days_left }.         \
                map    { |assignment| assignment.as_cli_string }.     \
                join("\n")
  end

  def list_all_assignments
    str = ''
    sqlite_cmd("SELECT * FROM #{PrimaryTable};").each do |params|
      assignment = Assignment.new(*params)
      str = str + assignment.as_cli_string
    end
    str
  end

  def update_assignment(a, col, val)
    sqlite_cmd("UPDATE assignments SET #{col} = '#{val}' WHERE #{assignment_params_for_sql(a)};")
  end
  
  def archive_assignment(a)
    update_assignment(a, 'archived', Archived)
  end
  
  def select_assignments_by_colval(col, val)
    assignments = []
    sqlite_cmd("SELECT * FROM assignments WHERE #{col} LIKE '%#{val}%';").each do |row|
      assignments.push Assignment.new(*row)
    end
    return assignments
  end

  def delete_assignment(a)
    sqlite_cmd("DELETE FROM assignments WHERE (#{assignment_params_for_sql(a)});")
  end

  def add_assignment(a)
    sqlite_cmd("INSERT INTO assignments VALUES('#{a.name}', '#{a.klass}', '#{a.assigned_date}', '#{a.due_date}', \
                  #{a.progress}, #{a.archived ? 1 : 0}, '#{a.note}')")
  end

  private

  def assignment_params_for_sql(a)
    "name = '#{a.name}' AND klass = '#{a.klass}' AND adate = '#{a.assigned_date}' AND ddate = '#{a.due_date}'\
               AND progress = #{a.progress} AND archived = #{a.archived ? 1 : 0} AND note = '#{a.note}'"
  end

  def sqlite_cmd(str)
    begin
      @db = SQLite3::Database.open DatabasePath 
      @db.execute(str)
    rescue SQLite3::Exception => e 
      STDERR.puts "Exception occurred"
      STDERR.puts e
    ensure
      @db.close if @db
    end
  end
  
end
