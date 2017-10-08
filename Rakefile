
#
# Vars 
#
#
tmp_dir = 'tmp'

#
# Dirs 
#
#
directory tmp_dir

#
# Tasks 
#

task :default => :print_help

desc "TODO: default task"
task :print_help do
 puts "make me show assignments"
end

desc "TODO: test"
task :test => tmp_dir do
  ruby 'lib/assignment_tracker.rb'
end

desc "clean up directory"
task :clean do
  Dir::rmdir(tmp_dir)
end
