StoreIt Protocol v0.5
=====================
---

#### 1. Introduction

Hello, this is the documentation for the StoreIt protocol. It is used to com- municate with our server. We will be implementing this protocol on top of WEBSOCKETS to enjoy its messaging model.
Everything should be JSON objects.

#### 2. The JSON data structures

##### 2.1 Command

```javascript
{
	"uid": unique_command_id,
	"command": command_name,
	"parameters": {
		"parameter1Name": parameter1,
		"parameter2Name": parameter2,
	}
}
```

##### 2.2 Response

```javascript
{
	"code": code,
	"text": response_message,
	"commandUid": command_id,
	"command": "RESP",
	(optional) "parameters": {
		...
	}
}
```
TODO: document possible errors.

##### 2.3 Commands

###### SUBS

Create a new StoreIt account. In case of success, a call to this will send a confirmation email to the user.

```javascript
{
    "uid": 5823,
    "command": "SUBS",
    "parameters": {
        "email": "john.doe@happy.com",
        "password": "H7&fû_fh47p(J0"
    }
}
```
Errors can be:

* BADPASSWORD: {code: 11, msg: 'Invalid password'},
* EXISTINGUSER: {code: 12, msg: 'Users already exists'},

###### AUTH

Use when the user is attempting to login with its StoreIt credentials. This returns a token to use with JOIN (see next command).

```javascript
{
	"uid": 8763,
	"command": "AUTH"
	"parameters": {
      "email": "john.doe@happy.com",
      "password": "H7&fû_fh47p(J0",
	}
}
```

Errors can be:

* BADCREDENTIALS: ‘CODE: 1, MSG: 'Invalid credentials'}

The response will looks like this:

```javascript
{
	"code": 0,
	"text": "success",
	"commandUid": 42,
	"command": "RESP",
	"parameters": {
		"accessToken": "34j8b4jhb343hbKJH54"
	}
}
```

###### JOIN

From a client to the server.
This is the first request to make whenever a client wants to get online.

```javascript
{
  "uid": 263,
  "command": "JOIN",
  "parameters": {
    "auth": {
      "type": "fb", // fb for facebook, gg for google, and si for StoreIt login
      "accessToken": "34j8b4jhb343hbKJH54", // get it from OAuth requests or AUTH request
    },
    "hosting": [
      'QmNMNRCgNBvkdXyXuVa2cHwTJJ9wtJQht1Njx1pqNBC9cV',
      'QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG'
    ]
  }
}
```

The response will contain a FILE object named "home" and user profile info. Example :

```javascript
{
	"code": 0,
	"text": "welcome",
	"commandUid": 42,
	"command": "RESP",
	"parameters": {
		"home": FILEObject,
		"userProfile": {"picture": "pic.jpg"}
	}
}
```

Errors can be:

* BADCREDENTIALS: {code: 1, msg: 'Invalid credentials'}

##### FDEL

From a client or the server.
Delete a file/directory.

```javascript
{
	"uid": 765,
	"command": "FDEL",
	"parameters": {
		"files": ["/a.txt", "/archive/b.txt", "/dir"]
	}
}
```

###### FADD

From a client or a server.
Add a file to the user three.

```javascript
{
	"uid": 766,
	"command": "FADD",
	"parameters": {
		"files": [FILEObject, ...]
	}
}
```

###### FUPT

From a client or a server.
Update a file.

```javascript
{
	"uid": 767,
	"command": "FUPT",
	"parameters": {
		"files": [FILEObject, ...]
	}
}
```

You should do only one FUPT per file/directory and omit the files parameter of your directory. For example, if your home is :

```ascii
| foo
L___ bar.txt
L___ pictures
```

And you want to update foo's timestamp, just send :

```javascript
{
	"uid": 767,
	"command": "FUPT",
	"parameters": {
		"files": [{
			"path": "/foo",
			"metadata": "updated metadata",
			"IPFSHash": null,
			"isDir": true,
			"files": null
		}]
	}
}
```

###### FMOV

From a client or a server.
move or rename a file.

```javascript
{
	"uid": 768,
	"command": "FMOV",
	"parameters": {
		"src": "/foo/bar.txt"
		"dest": "/foo/toto.txt"
	}
}
```

If you are moving a file, please don't omit the file name in the destination. For example :

DON'T DO:

```javascript
{
	"src": "/foo/bar"
	"dest": "/target/"
}
```

expecting to move /foo/bar into /target/bar

DO:

```javascript
{
	"src": "/foo/bar"
	"dest": "/target/bar"
}
```


###### FSTR

From the server to a client
Store an IPFS object

```javascript
{
	"uid": 7668,
	"command": "FSTR",
	"parameters": {
		"hash": "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
		"keep": true|false
	}
}
```

If the "keep" parameter is false, the object should be deleted. Otherwise it should be downloaded from IPFS and stored in the local repository.

##### 2.4 FILE object

This object describe a file or a directory.

```javascript
{
	"path": "/foo/bar",
	"metadata": metadata,
	"IPFSHash": "IPFS hash of all the data in the file",
	"isDir": true,
	"files": {
		"foo.txt": FILEObject,
		"someDirectory": FILEObject,
	}
}```
