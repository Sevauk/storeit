CREATE USER server LOGIN;

DROP TABLE client;

CREATE TABLE client (
    id int,
    username varchar(255),
    passwd_hash varchar(255),
    file_tree text
);

INSERT INTO client VALUES(0, 'sevauk', 'zulu', '{
        "path": "./",
        "metadata": "0",
        "unique_hash": "unique_hash",
        "kind": 0, 
        "files": [
        ]
    }');

INSERT INTO client VALUES(0, 'matt', 'zulu', '{
        "path": "./",
        "metadata": "0",
        "unique_hash": "unique_hash",
        "kind": 0, 
        "files": [
        ]
    }');

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO server;
