# Migration Memo: Neon → Cloudflare D1

**Date:** 2026-03-13
**Status:** Pending — resume after context reset

## What's Done (10 commits on main)

Full MVP implemented: monorepo (frontend/ + backend/ + contracts/), Hono API, Prisma + Neon, Better Auth, Flutter + Riverpod + Dio. All 9 plan tasks complete. Backend tests: 31/31 pass. Frontend tests: 8/9 (1 pre-existing failure).

Git remote: https://github.com/lasharela/spectrum (NOT pushed yet — remote has older Flutter-only commits, needs force push)

Wrangler authenticated: lasharela@gmail.com, Account ID: f5ee445e37fdf7228ac5eabf509ee9ec

## What Needs to Change

### Goal: Keep everything inside Cloudflare (no external DB)

Replace Neon Postgres with **Cloudflare D1** (SQLite-based, native to Workers).

### 1. Prisma Schema Changes (`backend/src/db/schema.prisma`)

Current:
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

Change to:
```prisma
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")  // for local dev/migrations
}
```

Key SQLite differences:
- No `String[]` type — tags on Post model must become a separate Tag table or store as JSON string
- `@default(cuid())` works fine
- `DateTime` works but stored as text
- `@@index` works

### 2. Prisma Client Changes (`backend/src/db/client.ts`)

Current: Uses `@prisma/adapter-neon` + `@neondatabase/serverless`

Change to: Use `@prisma/adapter-d1`
```typescript
import { PrismaD1 } from "@prisma/adapter-d1";
import { PrismaClient } from "@prisma/client";

export function createPrismaClient(d1: D1Database): PrismaClient {
  const adapter = new PrismaD1(d1);
  return new PrismaClient({ adapter });
}
```

### 3. Package.json Dependencies

Remove:
- `@prisma/adapter-neon`
- `@neondatabase/serverless`

Add:
- `@prisma/adapter-d1`

### 4. Wrangler Config (`backend/wrangler.toml`)

Add D1 binding:
```toml
[[d1_databases]]
binding = "DB"
database_name = "spectrum-db"
database_id = "<will be generated>"
```

Remove DATABASE_URL secret (D1 is bound directly).

### 5. Context Types (`backend/src/types/context.ts`)

Change AppBindings:
- Remove `DATABASE_URL: string`
- Add `DB: D1Database`

### 6. Index.ts Middleware

Change from `createPrismaClient(c.env.DATABASE_URL)` to `createPrismaClient(c.env.DB)` in all middleware blocks.

### 7. Community Routes

`String[]` for tags won't work in SQLite. Options:
- Store tags as comma-separated string: `tags: string` with `JSON.parse()`/`JSON.stringify()`
- Or create a PostTag join table

Recommend JSON string approach for simplicity.

### 8. Better Auth

Better Auth works with Prisma adapter regardless of underlying DB. Should work with D1/SQLite with no changes to auth config.

### 9. Migrations

D1 uses `wrangler d1 migrations` not Prisma migrate. Steps:
1. Create D1 database: `npx wrangler d1 create spectrum-db`
2. Generate SQL from Prisma: `prisma migrate diff --from-empty --to-schema-datamodel ./src/db/schema.prisma --script`
3. Apply: `npx wrangler d1 execute spectrum-db --file=migration.sql`

## After Migration: Remaining Tasks

1. **Force push to GitHub** (local monorepo replaces old Flutter-only remote)
2. **Set Cloudflare secret**: `BETTER_AUTH_SECRET`
3. **Deploy**: `pnpm run deploy:cf`
4. **GitHub Actions auto-deploy** for both backend (wrangler) and frontend (TBD — Flutter web? Or native builds?)

## Files to Modify

| File | Change |
|------|--------|
| `backend/src/db/schema.prisma` | postgresql → sqlite, tags String[] → String |
| `backend/src/db/client.ts` | Neon adapter → D1 adapter |
| `backend/src/types/context.ts` | DATABASE_URL → DB: D1Database |
| `backend/src/index.ts` | All middleware: pass c.env.DB |
| `backend/src/routes/community.ts` | tags handling (JSON string) |
| `backend/package.json` | Swap Neon deps for D1 adapter |
| `backend/wrangler.toml` | Add D1 binding, remove DATABASE_URL comment |
| `backend/test/setup.ts` | Update for D1/SQLite test setup |
| `contracts/community.yaml` | tags type stays string[] in API, just changes in DB |
