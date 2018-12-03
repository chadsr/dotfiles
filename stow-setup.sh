#!/usr/bin

# This script is the result of stow not supporting environment variables in .stowrc
# The day that stow can do that, I will simply stow .stowrc too and remove this :)

if echo "--target=${HOME}" > $HOME/.stowrc; then
    echo ".stowrc written to '$HOME/.stowrc' successfully"
else
    echo "Failed to write '$HOME/.stowrc'. Exiting."
    exit 1
fi

# Symlink the rest of the stow configuration to $HOME
stow stow

echo "Stow configured successfully in '$HOME'!"
echo "Now use 'stow <FOLDER>' to symlink contents to the HOME directory."