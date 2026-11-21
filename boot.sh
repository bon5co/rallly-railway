#!/bin/sh
# Rallly on Railway: build the server's settings from the Railway variables, run upstream's migrations, seed a verified administrator
# that can sign in with a password (the stock image only offers an emailed code), keep public registration off, start the stock server.
set -eu
cd /app

need() { eval "v=\${$1:-}"; [ -n "$v" ] || { echo "[railway-boot] $1 is required" >&2; exit 1; }; }
for n in DB_HOST DB_USER DB_PASS DB_NAME SECRET_PASSWORD RALLLY_ADMIN_EMAIL RALLLY_ADMIN_PASSWORD RAILWAY_PUBLIC_DOMAIN; do need "$n"; done
[ "${#SECRET_PASSWORD}" -ge 32 ] || { echo "[railway-boot] SECRET_PASSWORD must be at least 32 characters" >&2; exit 1; }
case "$RALLLY_ADMIN_EMAIL" in *[!A-Za-z0-9@._+-]*) echo "[railway-boot] RALLLY_ADMIN_EMAIL has characters outside A-Za-z0-9@._+-" >&2; exit 1;; esac

export PORT="${PORT:-8080}" HOSTNAME=0.0.0.0
export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME"
export NEXT_PUBLIC_BASE_URL="${NEXT_PUBLIC_BASE_URL:-https://$RAILWAY_PUBLIC_DOMAIN}"
export AUTH_URL="$NEXT_PUBLIC_BASE_URL"
# Rallly validates SUPPORT_EMAIL as an address with a top-level domain; a bare host such as localhost fails it and the server exits at boot.
case "$RAILWAY_PUBLIC_DOMAIN" in
  *.*) support_host="$RAILWAY_PUBLIC_DOMAIN" ;;
  *) support_host="$RAILWAY_PUBLIC_DOMAIN.example" ;;
esac
export SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@$support_host}"
# sign-in by emailed code creates an account for any unknown address; with registration off the account hook refuses it
export REGISTRATION_ENABLED=false
unset DB_PASS
echo "[railway-boot] serving $NEXT_PUBLIC_BASE_URL on $PORT"

npx prisma migrate deploy --config=./prisma.config.ts

# seed the administrator once: a verified user with the admin role plus a credential account holding a better-auth scrypt hash
# (salt:key, both hex; N=16384 r=16 p=1 dkLen=64 over the NFKC-normalised password, the salt passed as its hex text)
node -e '
const c=require("node:crypto"),e=process.env,hex=n=>c.randomBytes(n).toString("hex");
const salt=hex(16),N=16384,r=16;
const key=c.scryptSync(e.RALLLY_ADMIN_PASSWORD.normalize("NFKC"),salt,64,{N,r,p:1,maxmem:128*N*r*2}).toString("hex");
const em=e.RALLLY_ADMIN_EMAIL;
process.stdout.write(
 "INSERT INTO users (id,name,email,email_verified,role,updated_at) VALUES (\x27usr"+hex(10)+"\x27,\x27Admin\x27,\x27"+em+"\x27,true,\x27admin\x27,now()) ON CONFLICT (email) DO NOTHING;\n"+
 "INSERT INTO accounts (id,user_id,provider,provider_account_id,password,updated_at) SELECT \x27acc"+hex(10)+"\x27,u.id,\x27credential\x27,u.id,\x27"+salt+":"+key+"\x27,now() FROM users u WHERE u.email=\x27"+em+"\x27 ON CONFLICT (provider,provider_account_id) DO NOTHING;\n");
' | npx prisma db execute --config=./prisma.config.ts --stdin
echo "[railway-boot] administrator $RALLLY_ADMIN_EMAIL ensured"

exec "$@"
