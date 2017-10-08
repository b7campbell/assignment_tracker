
DatabasePath = 'db/assignments.db'
PrimaryTable = 'Assignments'
ProgressBarMaxChars = (`tput cols`.chomp.to_f / 3).to_i
ProgressBarChar = '='

# ===================
# Terminal Interface
# ===================

TERM_WIDTH           = `tput cols`.chomp.to_i
MENU_HEADER          = '[Homework Log Main Menu]' 
TERM_CENTER_POSITION = TERM_WIDTH / 2 - MENU_HEADER.length / 2

NotStarted = 1
Planned    = 2
InProgress = 3
Finished   = 4

Archived = 1
