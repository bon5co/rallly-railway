# Rallly wrapper for Railway. The official image runs its database migrations and then the server, creates accounts only through an
# emailed one-time code, and needs SMTP before anyone can sign in, so a fresh deploy has no way in. This image builds DATABASE_URL and the
# public URL from the Railway variables, binds the server to Railway's injected PORT, runs the migrations, seeds a verified administrator
# with a password from RALLLY_ADMIN_EMAIL / RALLLY_ADMIN_PASSWORD (once, only when no such user exists) and keeps public registration off.
# upstream: lukevella/rallly
FROM lukevella/rallly:4.17.1@sha256:2c35b8ec567a403207b4681f037be967f1efd04f06f75d9801841f25b7504e45

COPY --chmod=0755 boot.sh /railway-boot.sh

EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["node", "apps/web/server.js"]
