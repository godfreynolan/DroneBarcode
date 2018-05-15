PRAGMA foreign_keys = ON;

CREATE TABLE codes(
	cid INTEGER PRIMARY KEY AUTOINCREMENT,
	code VARCHAR(128) NOT NULL,
	codedata VARCHAR(128) NOT NULL,
	created TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_created_codes
AFTER INSERT ON codes
BEGIN
	UPDATE codes SET created = datetime('now') WHERE cid = new.cid;
END;

CREATE TABLE blockchain(
	bchash VARCHAR(128) NOT NULL PRIMARY KEY,
	bcdata VARCHAR(128) NOT NULL,
	bcnonce INTEGER NOT NULL,
	bccreated INTEGER NOT NULL,
	bcprevhash VARCHAR(128) NOT NULL
);

CREATE TABLE transactions(
	txsignature VARCHAR(128) NOT NULL PRIMARY KEY,
	bchash VARCHAR(128),
	txfrom VARCHAR(128) NOT NULL,
	txto VARCHAR(128) NOT NULL,
	txdata VARCHAR(256) NOT NULL,
	txcreated INTEGER NOT NULL,
	txspent INTEGER NOT NULL,
	FOREIGN KEY (bchash) REFERENCES blockchain(bchash)
);
