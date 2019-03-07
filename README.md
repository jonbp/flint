# Flint

A base installer for bedrock based WordPress sites.

## Usage

Navigate to the directory where your base bedrock site is installed and run the `flint` command.

Answer the questions when prompted, at the end of the installation you'll be provided with the username and password to login.

Flint will create the database for you, there is no need to create one before hand.

## Installation
To install Flint, ensure that your system meets the following requirements:

* WP-CLI

To install Flint on your system, download or clone this repo, navigate to it in your terminal and run the following commands:

~~~~
chmod +x flint.sh
sudo cp ./flint.sh /usr/local/bin/flint
~~~~

## Variables

If you regularly setup WordPress sites and use the same plugins on each one, or if you share the database credentials across projects in your dev environment, the variables file will come in handy.

The Variables file lives in `~/.config/flint/vars`.

It can easily be created by running the command `flint vars`. This command can also be ran to quickly edit the file. You can specify your preferred editor in the vars file too. 

Here's and example of this file:

~~~~
# Locale
locale='en_GB'

# Editor
editor='code'

# Admin User Details
wpuser='admin'
wpuser_email=''
wpuser_fname=''
wpuser_sname=''

# Plugins (Activated on install)
active_plugins=(
	"akismet"
	"advanced-custom-fields"
)

# Plugins
plugins=(
	"wordpress-seo"
	"hello"
)
~~~~