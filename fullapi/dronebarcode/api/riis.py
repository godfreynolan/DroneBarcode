# Block chain storage for barcode data sent by drone
#
# Luke Justice (justicelu97@gmail.com) 2018

import dronebarcode
import hashlib
from flask import Flask
from flask import request
from flask import jsonify
from flask import abort

#used for testing
import time

difficulty = 3
default_method = 'sha512'


def create_hash(block, algorithm=default_method):
    """Creates a hash using data in the block."""

    unhashed = block["bcprevhash"] + str(block["bccreated"]) + str(block["bcnonce"]) + block["bcdata"]
    hash_obj = hashlib.new(algorithm)
    hash_obj.update(unhashed.encode('utf-8'))
    hashed = hash_obj.hexdigest()
    return hashed


def is_valid_hash(block):
    """Validates the hash stored in the block."""

    if block["bchash"][:difficulty] != '0' * difficulty:
        return False
    return create_hash(block) == block["bchash"]


def is_valid_chain(block):
    """Checks if the block is in a valid portion of the chain."""

    # TODO: implement
    return True


def get_chain_length(block):
    """Returns the length of the chain to this block."""

    if block['bchash'] == '0':
        return 0
    
    count = 1
    connection = dronebarcode.model.get_db()
    while block['bcprevhash'] != '0':
        #if not is_valid_hash(block):
        #    print('Invalid Block found')
        #    return 0

        # get the previous block
        cur = connection.execute(
            "SELECT * "
            "FROM blockchain "
            "WHERE bchash = ?",
            (block['bcprevhash'],)
        )
        block = cur.fetchone()

        if block is None:
            return 0
        count += 1

    return count


def select_last_block():
    """Finds the last block in the longest chain."""

    # Select the end blocks in the chain
    connection = dronebarcode.model.get_db()
    cur = connection.execute(
        "SELECT * "
        "FROM blockchain bc1 "
        "WHERE bc1.bchash NOT IN ("
        "   SELECT bc2.bcprevhash FROM blockchain bc2"
        ") ORDER BY bccreated"
    )
    blocks = cur.fetchall()

    # if chain is empty
    if len(blocks) == 0:
        cur = connection.execute(
            "SELECT * "
            "FROM blockchain "
        )
        return cur.fetchone(), 0

    # Select only the end block with the longest length
    bestlength = get_chain_length(blocks[0])
    bestblock = blocks[0]
    for block in blocks:
        testlength = get_chain_length(block)
        if testlength > bestlength:
            bestlength = testlength
            bestblock = block

    return bestblock, bestlength


def clean_chain():
    """Removes all rogue chains."""

    # TODO: implement
    return True


@dronebarcode.app.route('/riis', methods=['POST'])
def index():
    """DEPRECATED."""

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
    """DEPRECATED."""

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
    """Returns information for continuing the chain."""

    context = {}
    context["status"] = 'ok'

    block, length = select_last_block()

    print(length)

    context['last_hash'] = block['bchash']
    context['hash_method'] = default_method
    context['difficulty'] = difficulty
    
    return jsonify(**context), 200


@dronebarcode.app.route('/chain', methods=['GET'])
def get_chain():
    """Gets all the chain data."""

    context = {}
    chain = []
    connection = dronebarcode.model.get_db()
    
    # Retrieving the stored chain data of the longest chain
    block, context['length'] = select_last_block()
    while block['bchash'] != '0':
        #chain.insert(0, block)
        chain.append(block)
        cur = connection.execute(
            "SELECT * "
            "FROM blockchain "
            "WHERE bchash = ?",
            (block['bcprevhash'],)
        )
        block = cur.fetchone()

    context['chain'] = chain
    context['hash_method'] = default_method
    context['difficulty'] = difficulty
    context['status'] = 'ok'
    return jsonify(**context), 200


@dronebarcode.app.route('/append', methods=['POST'])
def append():
    """Appends a block to the chain."""
    if not request.json:
        abort(400)
    context = {}
    block = request.json["block"]

    print(request.json)

    # Ensures inserts only happen after the last block
    last_block, _ = select_last_block()
    if block['prevhash'] != last_block['bchash']:
        abort(409)

    # Append the block
    connection = dronebarcode.model.get_db()
    connection.execute(
        "INSERT INTO blockchain "
        "VALUES (?, ?, ?, ?, ?)",
        (block['hash'], block['data'], block['nonce'], block['created'], block['prevhash'])
    )

    context["status"] = 'ok'
    return jsonify(**context), 200


@dronebarcode.app.route('/testmine', methods=['POST'])
def mine():
    """Mines and appends one block for testing."""

    context = {}
    context['status'] = 'ok'

    block, _ = select_last_block()

    test = {}
    test["bcnonce"] = 0
    test["bccreated"] = int(time.time())
    test["bcdata"] = str(request.json['data'])
    test['bcprevhash'] = block['bchash']
    test['bchash'] = create_hash(test)
    while test['bchash'][:difficulty] != '0' * difficulty:
        test['bcnonce'] += 1
        test['bchash'] = create_hash(test)

    connection = dronebarcode.model.get_db()
    connection.execute(
        "INSERT INTO blockchain "
        "VALUES (?, ?, ?, ?, ?)",
        (test['bchash'], test['bcdata'], test['bcnonce'], test['bccreated'], test['bcprevhash'])
    )

    context['block'] = test

    return jsonify(**context), 200
