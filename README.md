# rallly-railway

Wrapper image for [Rallly](https://github.com/lukevella/rallly) (open source meeting scheduling: propose dates, collect votes, find the time that works) on Railway.

It runs the official `lukevella/rallly` image, pinned by digest. The stock image signs people in only with an emailed one-time code (or a social provider), so a deploy without SMTP has no way in. This wrapper builds `DATABASE_URL` and the public URL from plain Railway variables, binds to the injected `PORT`, runs the database migrations, seeds one verified administrator with a password from `RALLLY_ADMIN_EMAIL` and `RALLLY_ADMIN_PASSWORD` (only when no such user exists) and keeps public registration off (`REGISTRATION_ENABLED=false`).

Needs PostgreSQL 14 or newer alongside it; the Railway template wires both. Licence of this wrapper: MIT. Rallly itself is released under the licence in its own repository.
