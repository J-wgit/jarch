
alias please='sudo'

# Directory Navigation
alias home='cd ~'
alias desk='cd ~/Desktop'
alias docs='cd ~/Documents'
alias down='cd ~/Downloads'
alias dev='cd ~/dev'
alias proj='cd ~/Projects'

# Shell configuration
alias bashrc='$EDITOR ~/.bashrc'
alias aliases='$EDITOR ~/.bash_aliases'
alias reload='source ~/.bashrc'
alias pathrc='$EDITOR ~/.profile'

# PACKAGE MANAGEMENT
alias update='paru'

# SYSTEM CONTROL
alias reboot='sudo systemctl reboot'
alias poweroff='sudo systemctl poweroff'
alias suspend='sudo systemctl suspend'
alias hibernate='sudo systemctl hibernate'
alias lock='loginctl lock-session'


# Random password
alias genpass='< /dev/urandom tr -dc "A-Za-z0-9!@#\$%^&*()" | head -c 32; echo'

# Find shortcuts
alias ffi='find . -iname'                            # find file by name (case-insensitive)
alias fff='find . -type f -iname'                    # find regular file
alias ffd='find . -type d -iname'                    # find directory
alias ffr='find . -type f -newer'                    # files newer than a reference file
alias ffbig='find . -type f -size +100M'             # find files >100 MB
alias ffempty='find . -type f -empty'                # find empty files
alias ffedirs='find . -type d -empty'                # find empty directories
