require 'sqlite3'

require_relative 'assignment.rb'
require_relative 'config.rb'

class DB
  def initialize 
  end

  def list_assignments
    str = ''
    sqlite_cmd("SELECT * FROM #{PrimaryTable};").each do |params|
      assignment = Assignment.new(*params)
      if !assignment.archived
        str = str + assignment.as_cli_string
      end
    end
    str
  end

  # def update_task
  #   update the object parameters as specified, use keyboard interface to select field, then change it
  # end
  
  # def archive_task
  # end

  # def delete_task
  # end

  def add_assignment(a)
    sqlite_cmd("INSERT INTO assignments VALUES(#{a.name}, #{a.klass}, #{a.assigned_date}, #{due_date},\
                   #{archived}, #{a.progress}, #{note})")
  end

  private

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
