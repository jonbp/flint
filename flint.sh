#!/usr/bin/env bash

# Get Variables File
if [ -f ~/.config/flint/vars ]; then
	source ~/.config/flint/vars
fi

# ——————
# VAR FILE EDIT START
# ——————

# Default Editor
if [ -z "$editor" ] ; then
	editor="nano"
fi

# Shortcut to edit vars file
if  [[ $1 = "vars" ]]; then
	mkdir -p ~/.config/flint
	$editor ~/.config/flint/vars
	exit
fi

# ——————
# VAR FILE EDIT END
# ——————

# Get local .env + check
if [ -f ./.env ]; then
	source ./.env
else
	echo -e '\033[91mError:\033[0m .env not found. You need to be inside a bedrock directory.' >&2
	exit 0
fi

# WP CLI Check
if ! [ -x "$(command -v wp)" ]; then
	echo -e '\033[91mError:\033[0m WP-CLI is not installed.' >&2
	exit 0
fi

# ——————
# VARIABLES START
# ——————

# Style Variables
formatBreak="\033[90m―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\033[0m"

# ——————
# VARIABLES END
# ——————

# ——————
# USER INPUT START
# ——————

# Welcome Text
echo ""
echo -e $formatBreak
echo "Flint"
echo -e $formatBreak
echo ""

# WordPress User Inputs

echo -e $formatBreak
echo "1) WordPress User Details"
echo -e $formatBreak
echo ""

if [ -z "$wpuser" ] ; then
echo "WordPress Admin Username: "
read -e wpuser
echo ""
fi

if [ -z "$wpuser_email" ] ; then
echo "WordPress Admin Email: "
read -e wpuser_email
echo ""
fi

if [ -z "$wpuser_fname" ] ; then
echo "WordPress Admin First Name: "
read -e wpuser_fname
echo ""
fi

if [ -z "$wpuser_sname" ] ; then
echo "WordPress Admin Surname: "
read -e wpuser_sname
echo ""
fi

# Site Information Inputs

echo -e $formatBreak
echo "2) Site Details"
echo -e $formatBreak
echo ""

echo "Site Name: "
read -e sitename
echo ""

echo "Tagline: "
read -e tagline
echo ""

echo "Base Pages (Sererate page names with commas): "
read -e allpages
echo ""

# Plugin Option Inputs

echo -e $formatBreak
echo "3) Plugins"
echo -e $formatBreak
echo ""

echo "Install WooCommerce? (y/n)"
read -e woo
echo ""

echo "Disable Blog? (y/n)"
read -e disableblog
echo ""

echo "Disable Comments? (y/n)"
read -e disablecomments
echo ""

echo "Disable Search? (y/n)"
read -e disablesearch

echo ""
echo -e $formatBreak
echo ""

# User confirmation
echo "Are you ready to proceed? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
	echo ""
	echo -e $formatBreak
	echo ""
	echo "Aborted."
	echo ""
	exit 1
fi

echo ""
echo -e $formatBreak
echo ""
echo "Running install..."
echo ""

# ——————
# USER INPUT END
# ——————

# ——————
# BASE INSTALLATION START
# ——————

# Parse the current directory name
currentdirectory=${PWD##*/}

# Generate random 16 character password
password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 16)

# Create database and install WordPress database structure
wp db create
wp core install --url="$WP_HOME" --title="$sitename" --admin_user="$wpuser" --admin_password="$password" --admin_email="$wpuser_email"
wp option update blogdescription "$tagline"

# Add a name to the admin user
wp user update $wpuser --first_name="$wpuser_fname" --last_name="$wpuser_sname" --display_name="$wpuser_fname $wpuser_sname"

# Discourage Search Engines
wp option update blog_public 0

# Remove the sample page and create a 'Home' page
wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="sample-page" --field=ID --format=ids)
wp post create --post_type=page --post_title=Home --post_status=publish --post_author=$(wp user get $wpuser --field=ID)

# Set the Front Page to our new 'Home' page
wp option update show_on_front 'page'
wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids)

# Create pages from the comma seperated input
export IFS=","
for page in $allpages; do
	wp post create --post_type=page --post_status=publish --post_author=$(wp user get $wpuser --field=ID) --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')"
done

# Flush URLs
wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard

# ——————
# BASE INSTALLATION END
# ——————

# ——————
# PLUGIN INSTALLATION START
# ——————

# WooCommerce Install Option
if [ "$woo" == y ] ; then
	active_plugins+=('woocommerce')
fi

# Disable Plugin Options
if [ "$disableblog" == y ] ; then
	active_plugins+=('disable-blog')
fi
if [ "$disablecomments" == y ] ; then
	active_plugins+=('disable-comments')
fi
if [ "$disablesearch" == y ] ; then
	active_plugins+=('disable-search')
fi

# Composer Builder
for E in "${active_plugins[@]}"; do
    c_active_plugins+=("wpackagist-plugin/${E}")
done
for E in "${plugins[@]}"; do
    c_plugins+=("wpackagist-plugin/${E}")
done
composer require ${c_active_plugins[@]} ${c_plugins[@]}

if [ "$woo" == y ] ; then
	composer require wpackagist-theme/storefront
fi

# Activate Plugins
wp plugin activate ${active_plugins[*]}

# ——————
# PLUGIN INSTALLATION END
# ——————

# ——————
# HOUSEKEEPING START
# ——————

# Create a new main menu
wp menu create "Main Navigation"

# Add pages to the main menu from the comma seperated input
export IFS=" "
for pageid in $(wp post list --order="ASC" --orderby="date" --post_type=page --post_status=publish --posts_per_page=-1 --field=ID --format=ids); do
	wp menu item add-post main-navigation $pageid
done

# Language Updates
wp language core update
wp language plugin update --all 
wp language theme update --all

# ——————
# HOUSEKEEPING END
# ——————

echo ""
echo -e $formatBreak
echo ""
echo "Installation complete! Here are the login details:"
echo ""
echo "Site URL: $WP_HOME"
echo ""
echo "Username: $wpuser"
echo "Password: $password"
echo ""
echo -e $formatBreak
