# Chronicler [![Gem](https://img.shields.io/gem/v/chronicler.svg)](https://rubygems.org/gems/chronicler) [![Gem](https://img.shields.io/gem/dt/chronicler.svg)](https://rubygems.org/gems/chronicler)

Version control your (development) databases using Git

## Installation

Run the following command to install `Chronicler`:

    $ gem install "chronicler"

## Usage

Chronicler is a command-line-tool so for starters, you can print help instructions:

    $ crn help
    Commands:
      crn branch                 # List branches
      crn checkout [IDENTIFIER]  # Switch and load the specified branch or commit or tag (IDENTIFIER is optional)
      crn commit                 # Commit current state of selected databases
      crn destroy                # Remove Chronicler entirely
      crn help [COMMAND]         # Describe available commands or one specific command
      crn init [NAME]            # Create a new repository (NAME defaults to current Git repository or current user)
      crn list                   # List repositories
      crn load                   # Load database(s) of current commit
      crn log [INTERFACE]        # Show commit logs (INTERFACE is optional)
      crn new [BRANCH]           # Create a new branch (BRANCH defaults to current Git branch)
      crn open                   # Open current repository
      crn reset [COMMIT]         # Reset current branch to specified commit
      crn select                 # Select which databases to store
      crn status                 # Show current status
      crn tree                   # Print branch graph tree
      crn use [NAME]             # Use existing repository (NAME is optional)

## TODO

* Watch and unwatch switching branches
* Added memoization within CLI and Repository

## License

Copyright (c) 2016 Paul Engel, released under the MIT license

http://github.com/archan937 – http://twitter.com/archan937 – pm_engel@icloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
