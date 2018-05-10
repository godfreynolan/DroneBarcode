Perform the following commands from the fullapi/ directory



The following are for the first time setup

Create python virtual environment
> python3 -m venv env

Activate the python virtual environment
> source env/bin/activate
> pip install --upgrade pip setuptools wheel

Create a fresh environment for node
> pip install nodeenv
> nodeenv --python-virtualenv # might not be required. I recieve errors but it still runs.
> deactivate
> source env/bin/activate
> npm i -g npm

Install python dependencies and node modules
> pip install -e .
> npm install .



From here you are set up and ready to run.  Below is not part of the first time setup.

Subsequent starts only require activating the environment before starting the server
> source env/bin/activate

Packing the javascript (must be done before deploying the server if changes were made since last pack)
> node_modules/.bin/webpack
OR
> node_modules/.bin/webpack --watch # watches for changes in the javascript and packs dynamically

Deploying the server
> ./bin/instarun

To restart, delete the env/ folder
> rm -rf env/ # MAKE SURE YOU ARE IN THE RIGHT FOLDER



Directory guide

Scripts to help run the server easier
bin/

Base directory of the server
dronebarcode/

All of the api calls handled by the server are contained in these python scripts
dronebarcode/api/

All of the javascript for the website is in these files
dronebarcode/js/

The css and packed js file are found here
dronebarcode/static/

Contains the unrendered html templates for the website
dronebarcode/templates/

Handles the server-side distribution of the html files
dronebarcode/views/

Setup files for the database
dronebarcode/sql/
