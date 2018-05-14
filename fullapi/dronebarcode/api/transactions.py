# Transaction handling for the block chain
#
# Luke Justice (justicelu97@gmail.com) 2018

import dronebarcode
import ecdsa
import hashlib
import requests
import time
from flask import Flask
from flask import request
from flask import jsonify
from flask import abort

# used for testing
import random


tx_per_block = 4
default_method = 'sha512'


def hash(unhashed, algorithm=default_method):
    """Creates a hash using data in the block."""

    hash_obj = hashlib.new(algorithm)
    hash_obj.update(unhashed.encode('utf-8'))
    hashed = hash_obj.hexdigest()
    return hashed


def create_tx_signature(tx, private_key):
    """TEST FUNCTION - Hashes a transaction."""
    plain = tx["from"] + tx["to"] + tx["data"] + str(tx["created"])
    key = ecdsa.SigningKey.from_string(bytes.fromhex(private_key), curve=ecdsa.SECP256k1)
    return key.sign(plain.encode('utf-8')).hex()


def verify_tx_signature(tx):
    """Verify a signature."""
    plain = tx["from"] + tx["to"] + tx["data"] + str(tx["created"])
    try:
        key = ecdsa.VerifyingKey.from_string(bytes.fromhex(tx["from"]), curve=ecdsa.SECP256k1)
        return key.verify(bytes.fromhex(tx['signature']), plain.encode('utf-8'))
    except:
        return False


def merkle_root(tx_sigs):
    """Creates a merkle root hash of the signatures."""
    hashes = []
    for tx_sig in tx_sigs:
        hashes.append(hash(tx_sig))

    while len(hashes) > 1:
        for i in range(0, len(hashes), 2):
            if i == len(hashes) - 1:
                hashes[int(i / 2)] = hashes[i]
            else:
                hashes[int(i / 2)] = hash(hashes[i] + hashes[i + 1])
        hashes = hashes[:int(len(hashes) / 2)]

    print(hashes[0])
    return hashes[0]


def mine_block(data, diff, prev, method):
    """Mines a new block."""
    nonce = 0
    timestamp = int(time.time())
    hashed = 'a' * 64

    while hashed[:diff] != '0' * diff:
        nonce += 1
        plain = prev + str(timestamp) + str(nonce) + data
        hashed = hash(plain, method)

    connection = dronebarcode.model.get_db()
    connection.execute(
        "INSERT INTO blockchain "
        "VALUES (?, ?, ?, ?, ?)",
        (hashed, data, nonce, timestamp, prev)
    )
    return hashed


def update_block(data, diff, last, method):
    """Mines the last block with the new data."""
    nonce = 0
    timestamp = int(time.time())
    hashed = 'a' * 64

    connection = dronebarcode.model.get_db()
    cur = connection.execute(
        "SELECT bcprevhash FROM blockchain "
        "WHERE bchash = ?",
        (last,)
    )
    prev = cur.fetchone()['bcprevhash']

    while hashed[:diff] != '0' * diff:
        nonce += 1
        plain = prev + str(timestamp) + str(nonce) + data
        hashed = hash(plain, method)

    connection.execute(
        "UPDATE blockchain "
        "SET bchash = ?, bcdata = ?, bcnonce = ?, bccreated = ? "
        "WHERE bchash = ?",
        (hashed, data, nonce, timestamp, last)
    )
    return hashed


def update_transactions(sigs, block):
    """Updates the block hash of the tansactions."""
    connection = dronebarcode.model.get_db()
    for sig in sigs:
        connection.execute(
            "UPDATE transactions "
            "SET bchash = ? "
            "WHERE txsignature = ?",
            (block, sig)
        )


def mine(data):
    """Send data to miner."""
    response = requests.get("http://0.0.0.0:8000/block")
    diff = response.json()['difficulty']
    method = response.json()['hash_method']
    last = response.json()['last_hash']
    connection = dronebarcode.model.get_db()
    tx_sigs = []

    cur = connection.execute(
        "SELECT txsignature FROM transactions "
        "WHERE bchash = ? "
        "ORDER BY txcreated",
        (last,)
    )
    temp = cur.fetchall()
    for x in temp:
        tx_sigs.append(x['txsignature'])
    tx_sigs.append(data)

    # check if new block is necessary and create it
    if last == '0' or len(tx_sigs) > tx_per_block:
        block = mine_block(hash(data), diff, last, method)
        update_transactions(tx_sigs[-1:], block)
        print("(Create) Mined " + block)
        return block

    root_hash = merkle_root(tx_sigs)

    for tx in tx_sigs:
        connection.execute(
            "UPDATE transactions "
            "SET bchash = NULL "
            "WHERE txsignature = ?",
            (tx,)
        )
    block = update_block(root_hash, diff, last, method)
    update_transactions(tx_sigs, block)
    print("(Update) Mined " + block)
    return block


def is_valid_signature(tx):
    """Verifies a transaction with its public key."""
    return verify_tx_signature(tx)


@dronebarcode.app.route('/transaction', methods=['POST'])
def transaction():
    """Handles receiving a transaction."""

    if not request.json:
        abort(400)
    context = {}
    tx = request.json

    if not is_valid_signature(tx):
        abort(403)

    # Insert into the database
    connection = dronebarcode.model.get_db()
    connection.execute(
        "INSERT INTO transactions (txsignature, txfrom, txto, txdata, txcreated, txspent) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (tx['signature'], tx['from'], tx['to'], tx['data'], str(tx['created']), 0)
    )

    # Update the blockchain
    mine(tx['signature'])

    context["status"] = 'ok'
    return jsonify(**context), 200


@dronebarcode.app.route('/transaction', methods=['GET'])
def get_transactions():
    context = {}

    b = request.args.get('b', default='', type=str)

    connection = dronebarcode.model.get_db()
    if b == '':
        cur = connection.execute(
            "SELECT DISTINCT tx.* FROM transactions tx, blockchain bc "
            "WHERE tx.bchash = bc.bchash "
            "ORDER BY tx.txcreated DESC"
        )
        context['data'] = cur.fetchall()
    else:
        cur = connection.execute(
            "SELECT tx.* FROM transactions tx, blockchain bc "
            "WHERE bc.bchash = ? AND tx.bchash = bc.bchash "
            "ORDER BY tx.txcreated DESC",
            (b,)
        )
        context['data'] = cur.fetchall()

    context['status'] = 'ok'
    return jsonify(**context)


@dronebarcode.app.route('/wallet', methods=['GET'])
def create_wallet():
    """Creates a random public private key pair for testing."""
    context = {}
    context['status'] = 'ok'

    priv = ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1)
    context["public_key"] = priv.get_verifying_key().to_string().hex()
    context["private_key"] = priv.to_string().hex()

    return jsonify(**context)


@dronebarcode.app.route('/testtx', methods=['GET'])
def txtest():
    """Creates a random transaction for testing purposes."""
    context = {}
    tx = {}
    context['status'] = 'ok'

    priv = ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1)
    tx["from"] = priv.get_verifying_key().to_string().hex()
    print(tx['from'])

    privto = ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1)
    tx["to"] = privto.get_verifying_key().to_string().hex()

    tx["data"] = str(random.randint(1, 100))
    tx["created"] = int(time.time())

    tx["signature"] = create_tx_signature(tx, priv.to_string().hex())

    print('test')

    requests.post('http://localhost:8000/transaction', json=tx)

    return jsonify(**context), 200
