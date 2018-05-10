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
