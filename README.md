# Encrypted Instant Messaging 

## What?
This is a simple tool for sending messages to one or more people in a secure way. It uses AES-256 CBC, with HMAC thrown in for integrity checking. 

## How?

### Conceptual
0. Everyone agrees on what the secret key will be, and they don't write it on a post-it note and stick it under their keyboard. Seriously, I know it's tempting but come on.
1. One person is really awesome and starts the server for everyone else to use, then tells them what the hostname and port is. 
2. The server can't read the encrypted messages that it's getting, it just passes them along to everyone that connects.
3. Everyone starts up their own client, with the key they agreed on before, and puts in their handle so people know who is talking.
4. You talk about things that almost certainly didn't need this level of security, but whatever.

### Specific
1. Run the server executable somewhere like this: `server 9999`. This will start it on port `9999`
2. Run the client executable somewhere, like the same machine if you want to test it, or a different machine. You'll need to provide some sort of handle to use, and the secret key that will be used for encryption/decryption. Here is an example: `client localhost 9999 rubyFan Th1s1s@Re@lly$ecretKey!`
3. Do step 3 again, or else you're going to be a sad lonely person talking to yourself. If you're testing this on your local machine, that's unavoidable though.
4. Observe the messages being sent to all the connected clients

## FQA
Q: So any random person from the internet can just connect to my server?
A: If you set it up that way, sure! The thing is, when they send their message over, the server is going to send it to all the clients. The clients are going to use their keys to decrypt it, which isn't going to work. Legitamite messages coming from clients is always encrypted.

Q: No, but really, what if some internet rando finds the perfect TCP packet to buffer overflow my client/server into arbitrary code execution territory??!!
A: I mean, idk, maybe he will. I think the only place it could happen is in the socket `recv` method. I think that would be a bug within the core Ruby implementation, or its underlying C implementation though.

Q: Why are you using an HMAC? Also, what is an HMAC....
A: It's basically the secret key and the plain-text message hashed together. So the client creates this hashed value, and appends it to the plain-text message. That new message now gets encrypted and sent to the server. When the server sends it to all the clients, they will verify the HMAC on their end by using the key that they have. This is a good way to determine if someone has tampered with a message, or if it came from a different source entirely.

Q: Why did you make this?
A: Why does anyone do anything?