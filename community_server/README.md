# MyBalance Community API (0.7.65)

This is an **undeployed** community backend. The app's shared catalogue requires a real HTTPS origin; Google Drive backups do not supply one. No public endpoint is bundled by default.

## Local tests
```sh
cd community_server
python -m unittest -v test_server
python server.py serve
```

## Deployment
Use a persistent private SQLite volume and one instance, Python 3.11+, SQLite with JSON functions, and a production WSGI server (e.g. Gunicorn). Example: `MYBALANCE_DB=/data/community.sqlite3 gunicorn --bind 127.0.0.1:8000 --workers 2 server:application` from this directory. Put an HTTPS reverse proxy in front; enforce request size and per-IP rate limits at the proxy. The built-in development server is not for public deployment. Configure a domain, TLS, backups, monitoring, and moderation before public access. Set `mybalance/community_url` in Godot project settings to the origin for distribution, or manually enter the origin in the app.

## Moderation
New recipes remain pending until a moderator reviews them. Run `python server.py queue` to see pending recipes/reports. Review the text and ingredients, then `python server.py approve ID`, `reject ID`, or `hide ID` using the same database. There is deliberately no public moderator endpoint. For a public launch, staff must establish moderation procedures, enforce content terms, and provide a contact channel and privacy policy. The current build has no user blocking or Google sign-in for community accounts. Implement those before broad release.

## Privacy
Only recipe text, ingredient nutrition, portions, a pseudonymous installation account, ratings and reports are stored. No diary, personal profile or photo is uploaded by this version. Tokens are random, hashed at rest on the server, and stored locally on the device separately from the diary. The app can delete its community account and associated server records. Device loss may make the account unrecoverable. Rate limiting is basic and not abuse-proof; deployment needs additional abuse protections. Recipe data is user-submitted, not verified nutritional data. No public photos or comments yet.
