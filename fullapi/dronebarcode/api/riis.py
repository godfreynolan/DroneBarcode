#!flask/bin/python
import dronebarcode
from flask import Flask
from flask import request
from flask import jsonify
from flask import abort


@dronebarcode.app.route('/riis', methods=['POST'])
def index():
    if not request.json:
        abort(400)
    context = {}
    context["status"] = 'ok'
    context["codes_received"] = len(request.json["codes"])

    print(request.json["codes"])

    for code in request.json["codes"]:
        parameters = [str(code["code"]), str(code["data"])]
        print(parameters)
        connection = dronebarcode.model.get_db()
        connection.execute("""
            INSERT INTO codes (code, codedata, created) 
            VALUES (?, ?, '')
            """, parameters)
    
    return jsonify(**context), 200


@dronebarcode.app.route('/riis', methods=['GET'])
def get_code():
    context = {}
    results = []
    connection = dronebarcode.model.get_db()
    cur = connection.execute(
        "SELECT * "
        "FROM codes "
        "ORDER BY created DESC, cid DESC"
    )
    results_postids = cur.fetchall()

    for res in results_postids:
        result = {}
        result["code"] = res["code"]
        result["data"] = ' ' + str(res["cid"]) + ': ' + str(res["codedata"])
        results.append(result)

    context["status"] = "ok"
    context["data"] = results
    return jsonify(**context), 200


@dronebarcode.app.route('/block', methods=['GET'])
def get_block():
    if not request.json:
        abort(400)
    context = {}
    context["status"] = 'ok'
    
    return jsonify(**context), 200
