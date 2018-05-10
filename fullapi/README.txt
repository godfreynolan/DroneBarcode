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
