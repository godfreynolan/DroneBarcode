"""
dronebarcode index (main) view.

URLs include:
/
"""
import flask
import arrow
import dronebarcode


@dronebarcode.app.route('/')
def show_index():
    """Display / route."""
    return flask.render_template("index.html")
