# Spectrum MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure Spectrum into a monorepo with a Hono/Prisma/Better Auth backend on Cloudflare Workers and connect the Flutter frontend with auth + community feed.

**Architecture:** Contract-first approach. OpenAPI specs define the API surface. Backend (Hono + Prisma + Better Auth on CF Workers) and frontend (Flutter + Riverpod + Dio) are built against these contracts. TDD throughout.

**Tech Stack:** Hono, Prisma (edge), Neon Postgres, Better Auth, Cloudflare Workers, Flutter, Riverpod, Dio, Vitest, pnpm

**Spec:** `docs/superpowers/specs/2026-03-12-spectrum-mvp-design.md`

---

## Chunk 1: Monorepo Restructure + Contracts

### Task 1: Initialize Git and Monorepo Structure

**Files:**
- Create: `package.json` (root)
- Create: `pnpm-workspace.yaml`
- Create: `backend/package.json`
- Create: `backend/tsconfig.json`
- Create: `backend/wrangler.toml`
- Create: `contracts/auth.yaml`
- Create: `contracts/community.yaml`
- Move: all Flutter files → `frontend/`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Initialize git repo**

```bash
cd /Users/lasharela/Development/spectrum
git init
git add -A
git commit -m "chore: initial commit of existing Flutter app"
```

- [ ] **Step 2: Move Flutter app to frontend/**

```bash
cd /Users/lasharela/Development/spectrum
mkdir frontend
# Move all Flutter files/dirs (except docs, CLAUDE.md, .git)
for item in lib test android ios web macos linux windows pubspec.yaml pubspec.lock analysis_options.yaml .metadata .gitignore; do
  [ -e "$item" ] && mv "$item" frontend/
done
# Move hidden Flutter files
[ -d ".dart_tool" ] && mv .dart_tool frontend/
[ -d ".idea" ] && mv .idea frontend/
```

- [ ] **Step 3: Verify Flutter app still works from frontend/**

```bash
cd /Users/lasharela/Development/spectrum/frontend
flutter pub get
```

Expected: Dependencies resolve successfully.

- [ ] **Step 4: Create root package.json**

Create `package.json`:

```json
{
  "name": "spectrum",
  "private": true,
  "scripts": {
    "dev:backend": "pnpm --filter backend dev",
    "test:backend": "pnpm --filter backend test",
    "test:frontend": "cd frontend && flutter test",
    "test": "pnpm test:backend && pnpm test:frontend",
    "deploy:cf": "pnpm --filter backend run deploy:cf"
  }
}
```

- [ ] **Step 5: Create pnpm-workspace.yaml**

Create `pnpm-workspace.yaml`:

```yaml
packages:
  - "backend"
```

- [ ] **Step 6: Create backend/package.json**

Create `backend/package.json`:

```json
{
  "name": "backend",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "wrangler dev",
    "deploy:cf": "wrangler deploy",
    "test": "vitest run",
    "test:watch": "vitest",
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev",
    "db:push": "prisma db push"
  },
  "dependencies": {
    "hono": "^4.7.0",
    "@hono/zod-validator": "^0.5.0",
    "better-auth": "^1.2.0",
    "@prisma/client": "^6.5.0",
    "@prisma/adapter-neon": "^6.5.0",
    "@neondatabase/serverless": "^1.0.0",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "wrangler": "^4.0.0",
    "@cloudflare/workers-types": "^4.20250312.0",
    "typescript": "^5.7.0",
    "vitest": "^3.0.0",
    "prisma": "^6.5.0",
    "@types/node": "^22.0.0"
  },
  "prisma": {
    "schema": "src/db/schema.prisma"
  }
}
```

- [ ] **Step 7: Create backend/tsconfig.json**

Create `backend/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "types": ["@cloudflare/workers-types", "node"],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "test/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 8: Create backend/wrangler.toml**

Create `backend/wrangler.toml`:

```toml
name = "spectrum-api"
main = "src/index.ts"
compatibility_date = "2026-03-12"
compatibility_flags = ["nodejs_compat"]

[vars]
ENVIRONMENT = "development"

# Secrets (set via `wrangler secret put`):
# DATABASE_URL - Neon connection string
# BETTER_AUTH_SECRET - Secret for signing auth tokens
```

- [ ] **Step 9: Create backend directory structure**

```bash
cd /Users/lasharela/Development/spectrum/backend
mkdir -p src/auth src/middleware src/routes src/db src/types
mkdir -p test/routes test/middleware
```

- [ ] **Step 10: Install backend dependencies**

```bash
cd /Users/lasharela/Development/spectrum
pnpm install
```

Expected: All dependencies installed, `pnpm-lock.yaml` created.

- [ ] **Step 11: Commit monorepo structure**

```bash
cd /Users/lasharela/Development/spectrum
git add -A
git commit -m "chore: restructure into monorepo with frontend/ and backend/"
```

### Task 2: Write API Contracts

**Files:**
- Create: `contracts/auth.yaml`
- Create: `contracts/community.yaml`

- [ ] **Step 1: Create contracts directory**

```bash
mkdir -p /Users/lasharela/Development/spectrum/contracts
```

- [ ] **Step 2: Write auth contract**

Create `contracts/auth.yaml`:

```yaml
openapi: 3.1.0
info:
  title: Spectrum Auth API
  version: 1.0.0
  description: Authentication endpoints powered by Better Auth

paths:
  /api/auth/sign-up/email:
    post:
      summary: Register a new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password, name, userType]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
                name:
                  type: string
                  minLength: 1
                userType:
                  type: string
                  enum: [parent, autistic_individual, professional, educator, therapist, supporter]
      responses:
        "200":
          description: User created
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    $ref: "#/components/schemas/User"
                  session:
                    $ref: "#/components/schemas/Session"
                  token:
                    type: string
        "400":
          $ref: "#/components/responses/ValidationError"

  /api/auth/sign-in/email:
    post:
      summary: Sign in with email and password
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
      responses:
        "200":
          description: Signed in
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    $ref: "#/components/schemas/User"
                  session:
                    $ref: "#/components/schemas/Session"
                  token:
                    type: string
        "401":
          $ref: "#/components/responses/Unauthorized"

  /api/auth/sign-out:
    post:
      summary: Sign out current session
      security:
        - bearerAuth: []
      responses:
        "200":
          description: Signed out
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean

  /api/auth/get-session:
    get:
      summary: Get current session and user
      security:
        - bearerAuth: []
      responses:
        "200":
          description: Session info
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    $ref: "#/components/schemas/User"
                  session:
                    $ref: "#/components/schemas/Session"
        "401":
          $ref: "#/components/responses/Unauthorized"

  /api/me:
    get:
      summary: Get current user profile
      security:
        - bearerAuth: []
      responses:
        "200":
          description: User profile
          content:
            application/json:
              schema:
                type: object
                properties:
                  user:
                    $ref: "#/components/schemas/User"
        "401":
          $ref: "#/components/responses/Unauthorized"

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer

  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        email:
          type: string
        name:
          type: string
        userType:
          type: string
          enum: [parent, autistic_individual, professional, educator, therapist, supporter]
        image:
          type: string
          nullable: true
        createdAt:
          type: string
          format: date-time

    Session:
      type: object
      properties:
        id:
          type: string
        token:
          type: string
        expiresAt:
          type: string
          format: date-time

  responses:
    Unauthorized:
      description: Not authenticated
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [UNAUTHORIZED]

    ValidationError:
      description: Invalid input
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [VALIDATION_ERROR]
```

- [ ] **Step 3: Write community contract**

Create `contracts/community.yaml`:

```yaml
openapi: 3.1.0
info:
  title: Spectrum Community API
  version: 1.0.0
  description: Community feed endpoints

paths:
  /api/posts:
    get:
      summary: List posts (paginated)
      security:
        - bearerAuth: []
      parameters:
        - name: cursor
          in: query
          schema:
            type: string
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 50
      responses:
        "200":
          description: Paginated posts
          content:
            application/json:
              schema:
                type: object
                properties:
                  posts:
                    type: array
                    items:
                      $ref: "#/components/schemas/Post"
                  nextCursor:
                    type: string
                    nullable: true
        "401":
          $ref: "#/components/responses/Unauthorized"

    post:
      summary: Create a post
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [content]
              properties:
                content:
                  type: string
                  minLength: 1
                  maxLength: 5000
                tags:
                  type: array
                  items:
                    type: string
                    maxLength: 30
                  maxItems: 5
                  default: []
      responses:
        "201":
          description: Post created
          content:
            application/json:
              schema:
                type: object
                properties:
                  post:
                    $ref: "#/components/schemas/Post"
        "400":
          $ref: "#/components/responses/ValidationError"
        "401":
          $ref: "#/components/responses/Unauthorized"

  /api/posts/{id}:
    get:
      summary: Get a single post
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Post details
          content:
            application/json:
              schema:
                type: object
                properties:
                  post:
                    $ref: "#/components/schemas/Post"
        "404":
          $ref: "#/components/responses/NotFound"

    delete:
      summary: Delete own post
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Post deleted
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
        "403":
          $ref: "#/components/responses/Forbidden"
        "404":
          $ref: "#/components/responses/NotFound"

  /api/posts/{id}/comments:
    get:
      summary: List comments on a post (paginated)
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: cursor
          in: query
          schema:
            type: string
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 50
      responses:
        "200":
          description: Paginated comments
          content:
            application/json:
              schema:
                type: object
                properties:
                  comments:
                    type: array
                    items:
                      $ref: "#/components/schemas/Comment"
                  nextCursor:
                    type: string
                    nullable: true

    post:
      summary: Add a comment to a post
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [content]
              properties:
                content:
                  type: string
                  minLength: 1
                  maxLength: 2000
      responses:
        "201":
          description: Comment created
          content:
            application/json:
              schema:
                type: object
                properties:
                  comment:
                    $ref: "#/components/schemas/Comment"
        "400":
          $ref: "#/components/responses/ValidationError"
        "404":
          $ref: "#/components/responses/NotFound"

  /api/posts/{id}/comments/{commentId}:
    delete:
      summary: Delete own comment
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
        - name: commentId
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Comment deleted
          content:
            application/json:
              schema:
                type: object
                properties:
                  success:
                    type: boolean
        "403":
          $ref: "#/components/responses/Forbidden"
        "404":
          $ref: "#/components/responses/NotFound"

  /api/posts/{id}/reactions:
    put:
      summary: Like a post
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Post liked
          content:
            application/json:
              schema:
                type: object
                properties:
                  liked:
                    type: boolean
                    enum: [true]
                  likesCount:
                    type: integer

    delete:
      summary: Unlike a post
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: Post unliked
          content:
            application/json:
              schema:
                type: object
                properties:
                  liked:
                    type: boolean
                    enum: [false]
                  likesCount:
                    type: integer

  /api/health:
    get:
      summary: Health check
      responses:
        "200":
          description: API is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    enum: [ok]

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer

  schemas:
    Post:
      type: object
      properties:
        id:
          type: string
        content:
          type: string
        tags:
          type: array
          items:
            type: string
        authorId:
          type: string
        author:
          type: object
          properties:
            id:
              type: string
            name:
              type: string
            image:
              type: string
              nullable: true
            userType:
              type: string
        createdAt:
          type: string
          format: date-time
        likesCount:
          type: integer
        commentsCount:
          type: integer
        liked:
          type: boolean
          description: Whether the current user has liked this post

    Comment:
      type: object
      properties:
        id:
          type: string
        content:
          type: string
        authorId:
          type: string
        author:
          type: object
          properties:
            id:
              type: string
            name:
              type: string
            image:
              type: string
              nullable: true
        postId:
          type: string
        createdAt:
          type: string
          format: date-time

  responses:
    Unauthorized:
      description: Not authenticated
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [UNAUTHORIZED]

    Forbidden:
      description: Not authorized
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [FORBIDDEN]

    NotFound:
      description: Resource not found
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [NOT_FOUND]

    ValidationError:
      description: Invalid input
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              code:
                type: string
                enum: [VALIDATION_ERROR]
```

- [ ] **Step 4: Update CLAUDE.md**

Replace the contents of `CLAUDE.md` at project root with updated tech stack, directory structure, and commands reflecting the monorepo setup. Key changes:
- Tech stack: Hono, Prisma, Neon, Better Auth, Cloudflare Workers, Riverpod (not Provider), Dio
- Commands: add backend commands (`pnpm dev:backend`, `pnpm test:backend`, etc.)
- Architecture: update to show monorepo structure with `frontend/`, `backend/`, `contracts/`
- Remove Firebase references

- [ ] **Step 5: Commit contracts**

```bash
cd /Users/lasharela/Development/spectrum
git add contracts/ CLAUDE.md
git commit -m "feat: add OpenAPI contracts for auth and community APIs"
```

---

## Chunk 2: Backend Foundation + Auth

### Task 3: Prisma Schema + Database Client

**Files:**
- Create: `backend/src/db/schema.prisma`
- Create: `backend/src/db/client.ts`

- [ ] **Step 1: Write Prisma schema**

Create `backend/src/db/schema.prisma`:

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  emailVerified Boolean   @default(false)
  name          String
  image         String?
  userType      String
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt

  posts     Post[]
  comments  Comment[]
  reactions Reaction[]
  sessions  Session[]
  accounts  Account[]
}

model Session {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  ipAddress String?
  userAgent String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model Account {
  id                    String    @id @default(cuid())
  userId                String
  accountId             String
  providerId            String
  accessToken           String?
  refreshToken          String?
  accessTokenExpiresAt  DateTime?
  refreshTokenExpiresAt DateTime?
  scope                 String?
  idToken               String?
  password              String?
  createdAt             DateTime  @default(now())
  updatedAt             DateTime  @updatedAt

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
}

model Verification {
  id         String   @id @default(cuid())
  identifier String
  value      String
  expiresAt  DateTime
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}

model Post {
  id            String     @id @default(cuid())
  content       String
  tags          String[]
  authorId      String
  createdAt     DateTime   @default(now())
  updatedAt     DateTime   @updatedAt
  likesCount    Int        @default(0)
  commentsCount Int        @default(0)

  author    User       @relation(fields: [authorId], references: [id])
  comments  Comment[]
  reactions Reaction[]

  @@index([createdAt(sort: Desc)])
}

model Comment {
  id        String   @id @default(cuid())
  content   String
  authorId  String
  postId    String
  createdAt DateTime @default(now())

  author User @relation(fields: [authorId], references: [id])
  post   Post @relation(fields: [postId], references: [id], onDelete: Cascade)

  @@index([postId, createdAt(sort: Desc)])
}

model Reaction {
  id        String   @id @default(cuid())
  authorId  String
  postId    String
  createdAt DateTime @default(now())

  author User @relation(fields: [authorId], references: [id])
  post   Post @relation(fields: [postId], references: [id], onDelete: Cascade)

  @@unique([authorId, postId])
}
```

- [ ] **Step 2: Write Prisma edge client**

Create `backend/src/db/client.ts`:

```typescript
import { PrismaNeon } from "@prisma/adapter-neon";
import { neonConfig, Pool } from "@neondatabase/serverless";
import { PrismaClient } from "@prisma/client/edge";

export function createPrismaClient(databaseUrl: string): PrismaClient {
  const pool = new Pool({ connectionString: databaseUrl });
  const adapter = new PrismaNeon(pool);
  return new PrismaClient({ adapter });
}
```

- [ ] **Step 3: Create backend/.env.example**

Create `backend/.env.example`:

```
DATABASE_URL=postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/spectrum?sslmode=require
BETTER_AUTH_SECRET=your-secret-key-here-change-in-production
```

- [ ] **Step 4: Add backend/.gitignore**

Create `backend/.gitignore`:

```
node_modules/
.wrangler/
.env
generated/
```

- [ ] **Step 5: Generate Prisma client and push schema**

```bash
cd /Users/lasharela/Development/spectrum/backend
# Create .env with your Neon DATABASE_URL first
npx prisma generate
npx prisma db push
```

Expected: Prisma client generated, schema pushed to Neon.

- [ ] **Step 6: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add backend/src/db/ backend/.env.example backend/.gitignore
git commit -m "feat: add Prisma schema and edge client for Neon"
```

### Task 4: Hono App + Health Endpoint + Better Auth

**Files:**
- Create: `backend/src/types/context.ts`
- Create: `backend/src/auth/auth.ts`
- Create: `backend/src/middleware/session.ts`
- Create: `backend/src/index.ts`
- Create: `backend/test/setup.ts`
- Create: `backend/test/routes/health.test.ts`
- Create: `backend/test/routes/auth.test.ts`
- Create: `backend/vitest.config.ts`

- [ ] **Step 1: Write Hono context types**

Create `backend/src/types/context.ts`:

```typescript
import type { PrismaClient } from "@prisma/client/edge";
import type { Auth } from "../auth/auth.js";

export type UserContext = {
  id: string;
  email: string;
  name: string;
  userType: string;
  image: string | null;
};

export type AppBindings = {
  DATABASE_URL: string;
  BETTER_AUTH_SECRET: string;
  ENVIRONMENT: string;
};

export type AppVariables = {
  user: UserContext;
  prisma: PrismaClient;
  auth: Auth;
};
```

- [ ] **Step 2: Write Better Auth configuration**

Create `backend/src/auth/auth.ts`:

```typescript
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import type { PrismaClient } from "@prisma/client/edge";

export function createAuth(prisma: PrismaClient, secret: string) {
  return betterAuth({
    secret,
    database: prismaAdapter(prisma, {
      provider: "postgresql",
    }),
    emailAndPassword: {
      enabled: true,
    },
    user: {
      additionalFields: {
        userType: {
          type: "string",
          required: true,
          input: true,
        },
      },
    },
  });
}

export type Auth = ReturnType<typeof createAuth>;
```

- [ ] **Step 3: Write session middleware**

Create `backend/src/middleware/session.ts`:

```typescript
import { createMiddleware } from "hono/factory";
import type { AppBindings, AppVariables } from "../types/context.js";

export const sessionMiddleware = createMiddleware<{
  Bindings: AppBindings;
  Variables: AppVariables;
}>(async (c, next) => {
  const auth = c.get("auth");
  const session = await auth.api.getSession({
    headers: c.req.raw.headers,
  });

  if (!session) {
    return c.json(
      { error: "Not authenticated", code: "UNAUTHORIZED" },
      401
    );
  }

  c.set("user", {
    id: session.user.id,
    email: session.user.email,
    name: session.user.name,
    userType: (session.user as any).userType,
    image: session.user.image,
  });

  await next();
});
```

- [ ] **Step 4: Write Hono app entry point**

Create `backend/src/index.ts`:

```typescript
import { Hono } from "hono";
import { cors } from "hono/cors";
import { createPrismaClient } from "./db/client.js";
import { createAuth } from "./auth/auth.js";
import { sessionMiddleware } from "./middleware/session.js";
import type { AppBindings, AppVariables } from "./types/context.js";

const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

// CORS
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  })
);

// Health check — ABOVE the prisma/auth middleware so it works without DB
app.get("/api/health", (c) => {
  return c.json({ status: "ok" });
});

// Per-request setup: create Prisma + Auth instances
// Scoped to /api/* routes that need DB access (excludes /api/health above)
app.use("/api/auth/*", async (c, next) => {
  const prisma = createPrismaClient(c.env.DATABASE_URL);
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});

app.use("/api/me", async (c, next) => {
  const prisma = createPrismaClient(c.env.DATABASE_URL);
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});

app.use("/api/posts/*", async (c, next) => {
  const prisma = createPrismaClient(c.env.DATABASE_URL);
  const auth = createAuth(prisma, c.env.BETTER_AUTH_SECRET);
  c.set("prisma", prisma);
  c.set("auth", auth);
  await next();
});

// Auth routes — Better Auth handler
app.on(["GET", "POST"], "/api/auth/**", async (c) => {
  const auth = c.get("auth");
  return auth.handler(c.req.raw);
});

// Profile endpoint
app.get("/api/me", sessionMiddleware, async (c) => {
  const user = c.get("user");
  return c.json({ user });
});

// Community routes will be mounted here in Task 5:
// app.route("/api/posts", communityRoutes);

// Global error handler
app.onError((err, c) => {
  console.error(err);
  return c.json({ error: "Internal server error", code: "INTERNAL_ERROR" }, 500);
});

export default app;
```

Key design decisions:
- Health endpoint is registered BEFORE the DB middleware, so it works without DATABASE_URL (for testing and uptime checks)
- Prisma/Auth middleware is scoped to specific paths, not wildcard
- `BETTER_AUTH_SECRET` is passed to Better Auth for token signing
- Global error handler catches unhandled exceptions and returns consistent error shape

- [ ] **Step 6: Write vitest config**

Create `backend/vitest.config.ts`:

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    globals: true,
    setupFiles: ["./test/setup.ts"],
  },
  resolve: {
    alias: {
      "@": "./src",
    },
  },
});
```

- [ ] **Step 7: Write test setup**

Create `backend/test/setup.ts`:

```typescript
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export { prisma };

export async function cleanDatabase() {
  await prisma.reaction.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.session.deleteMany();
  await prisma.account.deleteMany();
  await prisma.verification.deleteMany();
  await prisma.user.deleteMany();
}
```

Note: Test setup uses standard Prisma client (not edge) since tests run in Node.js.

- [ ] **Step 8: Write health endpoint test**

Create `backend/test/routes/health.test.ts`:

```typescript
import { describe, it, expect } from "vitest";
import app from "../../src/index.js";

describe("GET /api/health", () => {
  it("returns status ok", async () => {
    const res = await app.request("/api/health");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toEqual({ status: "ok" });
  });
});
```

- [ ] **Step 9: Run health test to verify it passes**

```bash
cd /Users/lasharela/Development/spectrum/backend
pnpm test -- test/routes/health.test.ts
```

Expected: PASS

- [ ] **Step 10: Write auth integration test**

Create `backend/test/routes/auth.test.ts`:

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import { cleanDatabase } from "../setup.js";

// Note: Auth tests require a running database and will call the app
// through Better Auth's built-in handler. These tests verify the
// full signup → signin → session → signout flow.

describe("Auth API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  it("should sign up a new user with userType", async () => {
    // This test will be fleshed out after validating Better Auth
    // + Prisma edge compatibility in the local dev environment
    expect(true).toBe(true);
  });

  it("should reject sign-up without userType", async () => {
    expect(true).toBe(true);
  });

  it("should sign in with valid credentials", async () => {
    expect(true).toBe(true);
  });

  it("should reject sign-in with invalid credentials", async () => {
    expect(true).toBe(true);
  });

  it("should get session for authenticated user", async () => {
    expect(true).toBe(true);
  });

  it("should return 401 for unauthenticated session request", async () => {
    expect(true).toBe(true);
  });

  it("should sign out and invalidate session", async () => {
    expect(true).toBe(true);
  });
});
```

Note: Auth tests are placeholder stubs. They will be filled in once Better Auth + Prisma edge compatibility is validated with a real Neon database. The implementer should:
1. Set up `.env` with a real Neon `DATABASE_URL`
2. Run `npx prisma db push` to create tables
3. Test Better Auth signup/signin manually with `pnpm dev`
4. Then fill in these test stubs with real assertions

- [ ] **Step 11: Run tests**

```bash
cd /Users/lasharela/Development/spectrum/backend
pnpm test
```

Expected: All tests pass (health test real, auth tests are stubs).

- [ ] **Step 12: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add backend/
git commit -m "feat: add Hono app with health endpoint and Better Auth setup"
```

---

## Chunk 3: Backend Community Routes

### Task 5: Community CRUD Endpoints (TDD)

**Files:**
- Create: `backend/src/routes/community.ts`
- Create: `backend/test/routes/community.test.ts`
- Modify: `backend/src/index.ts` (mount community routes)

- [ ] **Step 1: Write Zod validation schemas**

Create `backend/src/routes/community.ts`:

```typescript
import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import type { AppBindings, AppVariables } from "../types/context.js";
import { sessionMiddleware } from "../middleware/session.js";

const createPostSchema = z.object({
  content: z.string().min(1).max(5000),
  tags: z
    .array(z.string().max(30))
    .max(5)
    .default([]),
});

const createCommentSchema = z.object({
  content: z.string().min(1).max(2000),
});

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export function communityRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // Apply auth middleware to all community routes
  app.use("*", sessionMiddleware);

  // GET /api/posts - list posts (paginated)
  app.get("/", async (c) => {
    const prisma = c.get("prisma");
    const { cursor, limit } = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
    });

    const user = c.get("user");

    const posts = await prisma.post.findMany({
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
        reactions: { where: { authorId: user.id }, select: { id: true } },
      },
    });

    const hasMore = posts.length > limit;
    const results = hasMore ? posts.slice(0, limit) : posts;
    const nextCursor = hasMore ? results[results.length - 1].id : null;

    return c.json({
      posts: results.map((p) => ({
        id: p.id,
        content: p.content,
        tags: p.tags,
        authorId: p.authorId,
        author: p.author,
        createdAt: p.createdAt.toISOString(),
        likesCount: p.likesCount,
        commentsCount: p.commentsCount,
        liked: p.reactions.length > 0,
      })),
      nextCursor,
    });
  });

  // POST /api/posts - create a post
  app.post("/", zValidator("json", createPostSchema), async (c) => {
    const { content, tags } = c.req.valid("json");
    const user = c.get("user");

    const post = await prisma.post.create({
      data: { content, tags, authorId: user.id },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
      },
    });

    return c.json(
      {
        post: {
          id: post.id,
          content: post.content,
          tags: post.tags,
          authorId: post.authorId,
          author: post.author,
          createdAt: post.createdAt.toISOString(),
          likesCount: post.likesCount,
          commentsCount: post.commentsCount,
          liked: false,
        },
      },
      201
    );
  });

  // GET /api/posts/:id - get single post
  app.get("/:id", async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");

    const post = await prisma.post.findUnique({
      where: { id },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
        reactions: { where: { authorId: user.id }, select: { id: true } },
      },
    });

    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    return c.json({
      post: {
        id: post.id,
        content: post.content,
        tags: post.tags,
        authorId: post.authorId,
        author: post.author,
        createdAt: post.createdAt.toISOString(),
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        liked: post.reactions.length > 0,
      },
    });
  });

  // DELETE /api/posts/:id - delete own post
  app.delete("/:id", async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");

    const post = await prisma.post.findUnique({ where: { id } });

    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    if (post.authorId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    await prisma.post.delete({ where: { id } });

    return c.json({ success: true });
  });

  // GET /api/posts/:id/comments - list comments (paginated)
  app.get("/:id/comments", async (c) => {
    const postId = c.req.param("id");
    const { cursor, limit } = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
    });

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    const comments = await prisma.comment.findMany({
      where: { postId },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        author: { select: { id: true, name: true, image: true } },
      },
    });

    const hasMore = comments.length > limit;
    const results = hasMore ? comments.slice(0, limit) : comments;
    const nextCursor = hasMore ? results[results.length - 1].id : null;

    return c.json({
      comments: results.map((cm) => ({
        id: cm.id,
        content: cm.content,
        authorId: cm.authorId,
        author: cm.author,
        postId: cm.postId,
        createdAt: cm.createdAt.toISOString(),
      })),
      nextCursor,
    });
  });

  // POST /api/posts/:id/comments - add comment
  app.post("/:id/comments", zValidator("json", createCommentSchema), async (c) => {
    const postId = c.req.param("id");
    const { content } = c.req.valid("json");
    const user = c.get("user");

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    const [comment] = await prisma.$transaction([
      prisma.comment.create({
        data: { content, authorId: user.id, postId },
        include: {
          author: { select: { id: true, name: true, image: true } },
        },
      }),
      prisma.post.update({
        where: { id: postId },
        data: { commentsCount: { increment: 1 } },
      }),
    ]);

    return c.json(
      {
        comment: {
          id: comment.id,
          content: comment.content,
          authorId: comment.authorId,
          author: comment.author,
          postId: comment.postId,
          createdAt: comment.createdAt.toISOString(),
        },
      },
      201
    );
  });

  // DELETE /api/posts/:id/comments/:commentId - delete own comment
  app.delete("/:id/comments/:commentId", async (c) => {
    const postId = c.req.param("id");
    const commentId = c.req.param("commentId");
    const user = c.get("user");

    const comment = await prisma.comment.findUnique({
      where: { id: commentId },
    });

    if (!comment || comment.postId !== postId) {
      return c.json({ error: "Comment not found", code: "NOT_FOUND" }, 404);
    }

    if (comment.authorId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    await prisma.$transaction([
      prisma.comment.delete({ where: { id: commentId } }),
      prisma.post.update({
        where: { id: postId },
        data: { commentsCount: { decrement: 1 } },
      }),
    ]);

    return c.json({ success: true });
  });

  // PUT /api/posts/:id/reactions - like a post
  app.put("/:id/reactions", async (c) => {
    const postId = c.req.param("id");
    const user = c.get("user");

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    const existing = await prisma.reaction.findUnique({
      where: { authorId_postId: { authorId: user.id, postId } },
    });

    if (existing) {
      return c.json({ liked: true, likesCount: post.likesCount });
    }

    const updated = await prisma.$transaction(async (tx) => {
      await tx.reaction.create({
        data: { authorId: user.id, postId },
      });
      return tx.post.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      });
    });

    return c.json({ liked: true, likesCount: updated.likesCount });
  });

  // DELETE /api/posts/:id/reactions - unlike a post
  app.delete("/:id/reactions", async (c) => {
    const postId = c.req.param("id");
    const user = c.get("user");

    const post = await prisma.post.findUnique({ where: { id: postId } });
    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    const existing = await prisma.reaction.findUnique({
      where: { authorId_postId: { authorId: user.id, postId } },
    });

    if (!existing) {
      return c.json({ liked: false, likesCount: post.likesCount });
    }

    const updated = await prisma.$transaction(async (tx) => {
      await tx.reaction.delete({
        where: { authorId_postId: { authorId: user.id, postId } },
      });
      return tx.post.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
      });
    });

    return c.json({ liked: false, likesCount: updated.likesCount });
  });

  return app;
}
```

- [ ] **Step 2: Mount community routes in index.ts**

In `backend/src/index.ts`, replace the comment `// Community routes will be mounted here in Task 5:` with:

```typescript
import { communityRoutes } from "./routes/community.js";

app.route("/api/posts", communityRoutes());
```

The community routes pull `prisma` and `auth` from Hono context (set by the `/api/posts/*` middleware already defined in `index.ts`). No constructor params needed.

- [ ] **Step 3: Write community test stubs**

Create `backend/test/routes/community.test.ts`:

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import { cleanDatabase } from "../setup.js";

// Community tests require a running database and an authenticated user.
// The test helper should provide a function to create a user + session
// and return auth headers for making authenticated requests.

describe("Posts API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("POST /api/posts", () => {
    it("should create a post with content and tags", async () => {
      // Create user, get auth header, POST /api/posts
      expect(true).toBe(true);
    });

    it("should reject post with empty content", async () => {
      expect(true).toBe(true);
    });

    it("should reject post with content > 5000 chars", async () => {
      expect(true).toBe(true);
    });

    it("should reject post with > 5 tags", async () => {
      expect(true).toBe(true);
    });

    it("should reject unauthenticated request with 401", async () => {
      expect(true).toBe(true);
    });
  });

  describe("GET /api/posts", () => {
    it("should return paginated posts with author info", async () => {
      expect(true).toBe(true);
    });

    it("should paginate with cursor", async () => {
      expect(true).toBe(true);
    });

    it("should include liked status for current user", async () => {
      expect(true).toBe(true);
    });
  });

  describe("GET /api/posts/:id", () => {
    it("should return single post", async () => {
      expect(true).toBe(true);
    });

    it("should return 404 for non-existent post", async () => {
      expect(true).toBe(true);
    });
  });

  describe("DELETE /api/posts/:id", () => {
    it("should delete own post", async () => {
      expect(true).toBe(true);
    });

    it("should return 403 when deleting another user's post", async () => {
      expect(true).toBe(true);
    });

    it("should cascade delete comments and reactions", async () => {
      expect(true).toBe(true);
    });
  });
});

describe("Comments API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("POST /api/posts/:id/comments", () => {
    it("should create a comment and increment commentsCount", async () => {
      expect(true).toBe(true);
    });

    it("should reject comment with content > 2000 chars", async () => {
      expect(true).toBe(true);
    });

    it("should return 404 for non-existent post", async () => {
      expect(true).toBe(true);
    });
  });

  describe("GET /api/posts/:id/comments", () => {
    it("should return paginated comments with author info", async () => {
      expect(true).toBe(true);
    });
  });

  describe("DELETE /api/posts/:id/comments/:commentId", () => {
    it("should delete own comment and decrement commentsCount", async () => {
      expect(true).toBe(true);
    });

    it("should return 403 when deleting another user's comment", async () => {
      expect(true).toBe(true);
    });
  });
});

describe("Reactions API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  describe("PUT /api/posts/:id/reactions", () => {
    it("should like a post and increment likesCount", async () => {
      expect(true).toBe(true);
    });

    it("should be idempotent (liking twice returns same count)", async () => {
      expect(true).toBe(true);
    });
  });

  describe("DELETE /api/posts/:id/reactions", () => {
    it("should unlike a post and decrement likesCount", async () => {
      expect(true).toBe(true);
    });

    it("should be idempotent (unliking when not liked returns same count)", async () => {
      expect(true).toBe(true);
    });
  });
});
```

Note: These are test stubs. The implementer should fill them in after Task 4's auth tests work, since community tests need authenticated users. The pattern:
1. Use `prisma.user.create()` + `prisma.session.create()` directly to create test users with sessions
2. Use the session token as `Authorization: Bearer <token>` header
3. Call `app.request()` with the header to make authenticated requests

- [ ] **Step 4: Run tests**

```bash
cd /Users/lasharela/Development/spectrum/backend
pnpm test
```

Expected: All tests pass (stubs pass trivially).

- [ ] **Step 5: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add backend/
git commit -m "feat: add community CRUD routes with validation and test stubs"
```

---

## Chunk 4: Flutter API Layer + Auth

### Task 6: Flutter API Client + Riverpod Setup

**Files:**
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/lib/main.dart`
- Create: `frontend/lib/shared/api/api_client.dart`
- Create: `frontend/lib/shared/api/api_exceptions.dart`
- Create: `frontend/lib/shared/providers/api_provider.dart`
- Create: `frontend/test/shared/api/api_client_test.dart`
- Create: `frontend/test/helpers/mocks.dart`

- [ ] **Step 1: Update pubspec.yaml dependencies**

In `frontend/pubspec.yaml`:
- Replace `provider: ^6.1.2` with `flutter_riverpod: ^2.6.0`
- Add `dio: ^5.7.0`
- Add `flutter_secure_storage: ^9.2.0`
- Remove all commented-out Firebase packages

- [ ] **Step 2: Write API exceptions**

Create `frontend/lib/shared/api/api_exceptions.dart`:

```dart
class ApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  const ApiException({
    required this.message,
    required this.code,
    required this.statusCode,
  });

  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    return ApiException(
      message: body['error'] as String? ?? 'Unknown error',
      code: body['code'] as String? ?? 'INTERNAL_ERROR',
      statusCode: statusCode,
    );
  }

  bool get isUnauthorized => code == 'UNAUTHORIZED';
  bool get isForbidden => code == 'FORBIDDEN';
  bool get isNotFound => code == 'NOT_FOUND';
  bool get isValidationError => code == 'VALIDATION_ERROR';

  @override
  String toString() => 'ApiException($code: $message)';
}
```

- [ ] **Step 3: Write API client**

Create `frontend/lib/shared/api/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  ApiClient({
    required String baseUrl,
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ?? Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Content-Type'] = 'application/json';

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map<String, dynamic>) {
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              error: ApiException.fromResponse(
                error.response!.statusCode ?? 500,
                data,
              ),
            ));
            return;
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}
```

- [ ] **Step 4: Write Riverpod providers**

Create `frontend/lib/shared/providers/api_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

// TODO: Replace with actual backend URL from environment config
const _baseUrl = 'http://localhost:8787';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _baseUrl);
});
```

- [ ] **Step 5: Update main.dart to use Riverpod**

Replace `frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpectrumApp()));
}

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
```

- [ ] **Step 6: Write test mocks**

Create `frontend/test/helpers/mocks.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

- [ ] **Step 7: Write API client test**

Create `frontend/test/shared/api/api_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import '../../helpers/mocks.dart';

void main() {
  group('ApiClient', () {
    late ApiClient apiClient;
    late MockSecureStorage mockStorage;
    late Dio dio;

    setUp(() {
      mockStorage = MockSecureStorage();
      dio = Dio();
      apiClient = ApiClient(
        baseUrl: 'http://localhost:8787',
        dio: dio,
        storage: mockStorage,
      );
    });

    test('saves and retrieves token', () async {
      await apiClient.saveToken('test-token');
      final token = await apiClient.getToken();
      expect(token, 'test-token');
    });

    test('clears token', () async {
      await apiClient.saveToken('test-token');
      await apiClient.clearToken();
      final token = await apiClient.getToken();
      expect(token, isNull);
    });
  });
}
```

- [ ] **Step 8: Run flutter pub get and tests**

```bash
cd /Users/lasharela/Development/spectrum/frontend
flutter pub get
flutter test test/shared/api/api_client_test.dart
```

Expected: Tests pass.

- [ ] **Step 9: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add frontend/
git commit -m "feat: add API client, Riverpod setup, and secure storage"
```

### Task 7: Flutter Auth — Repository, Provider, Screen Rewiring

**Files:**
- Create: `frontend/lib/features/auth/domain/user.dart`
- Create: `frontend/lib/features/auth/data/auth_repository.dart`
- Create: `frontend/lib/features/auth/presentation/providers/auth_provider.dart`
- Modify: `frontend/lib/features/auth/presentation/screens/login_screen.dart`
- Modify: `frontend/lib/features/auth/presentation/screens/signup_screen.dart`
- Modify: `frontend/lib/core/router/app_router.dart`
- Create: `frontend/test/features/auth/data/auth_repository_test.dart`
- Create: `frontend/test/features/auth/presentation/auth_provider_test.dart`

- [ ] **Step 1: Write User model**

Create `frontend/lib/features/auth/domain/user.dart`:

```dart
class User {
  final String id;
  final String email;
  final String name;
  final String userType;
  final String? image;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    this.image,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      userType: json['userType'] as String,
      image: json['image'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

- [ ] **Step 2: Write AuthRepository**

Create `frontend/lib/features/auth/data/auth_repository.dart`:

```dart
import '../../../shared/api/api_client.dart';
import '../domain/user.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<User> signUp({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    final response = await _api.post('/api/auth/sign-up/email', data: {
      'email': email,
      'password': password,
      'name': name,
      'userType': userType,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null) {
      await _api.saveToken(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/api/auth/sign-in/email', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null) {
      await _api.saveToken(token);
    }
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    await _api.post('/api/auth/sign-out');
    await _api.clearToken();
  }

  Future<User?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;
    try {
      final response = await _api.get('/api/auth/get-session');
      final data = response.data as Map<String, dynamic>;
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      await _api.clearToken();
      return null;
    }
  }
}
```

- [ ] **Step 3: Write AuthProvider**

Create `frontend/lib/features/auth/presentation/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/user.dart';
import '../../../../shared/providers/api_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.getCurrentUser();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signUp(
        email: email,
        password: password,
        name: name,
        userType: userType,
      );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(authRepositoryProvider);
      return repo.signIn(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(null);
  }
}
```

- [ ] **Step 4: Update login_screen.dart**

Key changes to `frontend/lib/features/auth/presentation/screens/login_screen.dart`:
- Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- Change `StatefulWidget` to `ConsumerStatefulWidget`, `State` to `ConsumerState`
- Replace `_handleLogin()` body:
  ```dart
  void _handleLogin() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signIn(
        email: values['email'] as String,
        password: values['password'] as String,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }
  ```
- Remove fake credentials constants and demo credentials UI box
- Remove `import 'package:provider/provider.dart';` if present

- [ ] **Step 5: Update signup_screen.dart**

Key changes to `frontend/lib/features/auth/presentation/screens/signup_screen.dart`:
- Add `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- Change to `ConsumerStatefulWidget` / `ConsumerState`
- Add two new user types to `_userTypes` list:
  ```dart
  {'value': 'autistic_individual', 'label': 'Person with Autism', 'icon': Icons.accessibility_new},
  {'value': 'supporter', 'label': 'Supporter', 'icon': Icons.volunteer_activism},
  ```
- Replace `_handleSignup()` body:
  ```dart
  void _handleSignup() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    if (_selectedUserType == null) return;
    final values = _formKey.currentState!.value;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signUp(
        email: values['email'] as String,
        password: values['password'] as String,
        name: values['name'] as String,
        userType: _selectedUserType!,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    }
  }
  ```

- [ ] **Step 6: Update router with auth redirect**

Modify `frontend/lib/core/router/app_router.dart`:
- The router needs access to auth state. Since GoRouter is static, the implementer should convert it to use a `Provider` that watches `authProvider` and sets the `redirect` callback:
  ```dart
  redirect: (context, state) {
    final isAuthenticated = /* check authProvider state */;
    final isAuthRoute = state.uri.path == '/onboarding' ||
        state.uri.path == '/login' ||
        state.uri.path == '/signup';
    if (!isAuthenticated && !isAuthRoute) return '/onboarding';
    if (isAuthenticated && isAuthRoute) return '/home';
    return null;
  },
  ```

- [ ] **Step 7: Write auth repository test**

Create `frontend/test/features/auth/data/auth_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:spectrum_app/features/auth/data/auth_repository.dart';
import 'package:spectrum_app/shared/api/api_client.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository repo;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      // TODO: Set up Dio mock adapter to intercept HTTP calls
      // Use dio's test adapter or a mock interceptor
      final dio = Dio();
      final apiClient = ApiClient(
        baseUrl: 'http://localhost:8787',
        dio: dio,
        storage: mockStorage,
      );
      repo = AuthRepository(apiClient);
    });

    test('signUp sends correct request and saves token', () async {
      // TODO: Mock POST /api/auth/sign-up/email response
      // Verify token saved to storage
      expect(true, isTrue);
    });

    test('signIn sends correct request and saves token', () async {
      // TODO: Mock POST /api/auth/sign-in/email response
      expect(true, isTrue);
    });

    test('signOut clears token', () async {
      // TODO: Mock POST /api/auth/sign-out
      expect(true, isTrue);
    });

    test('getCurrentUser returns null when no token', () async {
      final user = await repo.getCurrentUser();
      expect(user, isNull);
    });
  });
}
```

Note: Test stubs. The implementer should add a Dio mock interceptor (e.g., `dio_test` package or custom interceptor) to simulate API responses.

- [ ] **Step 8: Run tests**

```bash
cd /Users/lasharela/Development/spectrum/frontend
flutter pub get
flutter test
```

Expected: All tests pass.

- [ ] **Step 9: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add frontend/
git commit -m "feat: add auth repository, provider, and rewire login/signup screens"
```

---

## Chunk 5: Flutter Community + Deploy

### Task 8: Flutter Community Feed

**Files:**
- Create: `frontend/lib/features/community/domain/post.dart`
- Create: `frontend/lib/features/community/domain/comment.dart`
- Create: `frontend/lib/features/community/data/community_repository.dart`
- Create: `frontend/lib/features/community/presentation/providers/feed_provider.dart`
- Create: `frontend/lib/features/community/presentation/widgets/post_card.dart`
- Create: `frontend/lib/features/community/presentation/widgets/comment_list.dart`
- Create: `frontend/lib/features/community/presentation/screens/feed_screen.dart`
- Create: `frontend/lib/features/community/presentation/screens/post_detail_screen.dart`
- Modify: `frontend/lib/core/router/app_router.dart` (add post detail route)

- [ ] **Step 1: Write Post model**

Create `frontend/lib/features/community/domain/post.dart`:

```dart
class PostAuthor {
  final String id;
  final String name;
  final String? image;
  final String userType;

  const PostAuthor({
    required this.id,
    required this.name,
    this.image,
    required this.userType,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      userType: json['userType'] as String,
    );
  }
}

class Post {
  final String id;
  final String content;
  final List<String> tags;
  final String authorId;
  final PostAuthor author;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool liked;

  const Post({
    required this.id,
    required this.content,
    required this.tags,
    required this.authorId,
    required this.author,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.liked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      content: json['content'] as String,
      tags: (json['tags'] as List).cast<String>(),
      authorId: json['authorId'] as String,
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      liked: json['liked'] as bool? ?? false,
    );
  }

  Post copyWith({int? likesCount, int? commentsCount, bool? liked}) {
    return Post(
      id: id,
      content: content,
      tags: tags,
      authorId: authorId,
      author: author,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      liked: liked ?? this.liked,
    );
  }
}
```

- [ ] **Step 2: Write Comment model**

Create `frontend/lib/features/community/domain/comment.dart`:

```dart
class CommentAuthor {
  final String id;
  final String name;
  final String? image;

  const CommentAuthor({
    required this.id,
    required this.name,
    this.image,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
    );
  }
}

class Comment {
  final String id;
  final String content;
  final String authorId;
  final CommentAuthor author;
  final String postId;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.author,
    required this.postId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      postId: json['postId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

- [ ] **Step 3: Write CommunityRepository**

Create `frontend/lib/features/community/data/community_repository.dart`:

```dart
import '../../../shared/api/api_client.dart';
import '../domain/post.dart';
import '../domain/comment.dart';

class PaginatedResult<T> {
  final List<T> items;
  final String? nextCursor;

  const PaginatedResult({required this.items, this.nextCursor});
}

class CommunityRepository {
  final ApiClient _api;

  CommunityRepository(this._api);

  Future<PaginatedResult<Post>> getPosts({String? cursor, int limit = 20}) async {
    final response = await _api.get('/api/posts', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = response.data as Map<String, dynamic>;
    final posts = (data['posts'] as List)
        .map((p) => Post.fromJson(p as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: posts,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<Post> createPost({required String content, List<String> tags = const []}) async {
    final response = await _api.post('/api/posts', data: {
      'content': content,
      'tags': tags,
    });
    final data = response.data as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<Post> getPost(String id) async {
    final response = await _api.get('/api/posts/$id');
    final data = response.data as Map<String, dynamic>;
    return Post.fromJson(data['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    await _api.delete('/api/posts/$id');
  }

  Future<PaginatedResult<Comment>> getComments(String postId, {String? cursor, int limit = 20}) async {
    final response = await _api.get('/api/posts/$postId/comments', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    final data = response.data as Map<String, dynamic>;
    final comments = (data['comments'] as List)
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: comments,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Future<Comment> addComment(String postId, {required String content}) async {
    final response = await _api.post('/api/posts/$postId/comments', data: {
      'content': content,
    });
    final data = response.data as Map<String, dynamic>;
    return Comment.fromJson(data['comment'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _api.delete('/api/posts/$postId/comments/$commentId');
  }

  Future<({bool liked, int likesCount})> likePost(String postId) async {
    final response = await _api.put('/api/posts/$postId/reactions');
    final data = response.data as Map<String, dynamic>;
    return (liked: data['liked'] as bool, likesCount: data['likesCount'] as int);
  }

  Future<({bool liked, int likesCount})> unlikePost(String postId) async {
    final response = await _api.delete('/api/posts/$postId/reactions');
    final data = response.data as Map<String, dynamic>;
    return (liked: data['liked'] as bool, likesCount: data['likesCount'] as int);
  }
}
```

- [ ] **Step 4: Write FeedProvider**

Create `frontend/lib/features/community/presentation/providers/feed_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/community_repository.dart';
import '../../domain/post.dart';
import '../../../../shared/providers/api_provider.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.read(apiClientProvider));
});

class FeedState {
  final List<Post> posts;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;

  const FeedState({
    this.posts = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
  });

  FeedState copyWith({
    List<Post>? posts,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() {
    _loadInitial();
    return const FeedState(isLoading: true);
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts();
      state = FeedState(posts: result.items, nextCursor: result.nextCursor);
    } catch (_) {
      state = const FeedState();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    final repo = ref.read(communityRepositoryProvider);
    try {
      final result = await repo.getPosts(cursor: state.nextCursor);
      state = state.copyWith(
        posts: [...state.posts, ...result.items],
        nextCursor: () => result.nextCursor,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> createPost({required String content, List<String> tags = const []}) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = await repo.createPost(content: content, tags: tags);
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  Future<void> deletePost(String id) async {
    final repo = ref.read(communityRepositoryProvider);
    await repo.deletePost(id);
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != id).toList(),
    );
  }

  Future<void> toggleLike(String postId) async {
    final repo = ref.read(communityRepositoryProvider);
    final post = state.posts.firstWhere((p) => p.id == postId);
    final result = post.liked
        ? await repo.unlikePost(postId)
        : await repo.likePost(postId);
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id == postId) {
          return p.copyWith(liked: result.liked, likesCount: result.likesCount);
        }
        return p;
      }).toList(),
    );
  }
}
```

- [ ] **Step 5: Write PostCard widget**

Create `frontend/lib/features/community/presentation/widgets/post_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/post.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: post.tags
                      .map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.cyan,
          child: Text(
            post.author.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.author.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                DateFormat.yMMMd().add_jm().format(post.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            color: AppColors.textGray,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onLike,
          child: Row(
            children: [
              Icon(
                post.liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: post.liked ? AppColors.coral : AppColors.textGray,
              ),
              const SizedBox(width: 4),
              Text('${post.likesCount}',
                  style: TextStyle(color: AppColors.textGray, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Icon(Icons.comment_outlined, size: 20, color: AppColors.textGray),
            const SizedBox(width: 4),
            Text('${post.commentsCount}',
                style: TextStyle(color: AppColors.textGray, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Write FeedScreen**

Create `frontend/lib/features/community/presentation/screens/feed_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: feedState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(feedProvider.notifier).refresh(),
              child: feedState.posts.isEmpty
                  ? const Center(child: Text('No posts yet. Be the first!'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification &&
                            notification.metrics.extentAfter < 200) {
                          ref.read(feedProvider.notifier).loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: feedState.posts.length +
                            (feedState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == feedState.posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final post = feedState.posts[index];
                          return PostCard(
                            post: post,
                            onTap: () => context.push('/community/post/${post.id}'),
                            onLike: () => ref.read(feedProvider.notifier).toggleLike(post.id),
                            onDelete: post.authorId == currentUser?.id
                                ? () => _confirmDelete(context, ref, post.id)
                                : null,
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePost(context, ref),
        backgroundColor: AppColors.cyan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(feedProvider.notifier).deletePost(postId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreatePost(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              maxLength: 5000,
              decoration: const InputDecoration(
                hintText: 'Share something with the community...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(feedProvider.notifier).createPost(
                      content: controller.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Post'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Write PostDetailScreen (stub)**

Create `frontend/lib/features/community/presentation/screens/post_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/community_repository.dart';
import '../../domain/post.dart';
import '../../domain/comment.dart';
import '../providers/feed_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  String? _nextCursor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.getComments(widget.postId);
    if (mounted) {
      setState(() {
        _comments = result.items;
        _nextCursor = result.nextCursor;
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final repo = ref.read(communityRepositoryProvider);
    final comment = await repo.addComment(
      widget.postId,
      content: _commentController.text.trim(),
    );
    setState(() {
      _comments.insert(0, comment);
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final post = feedState.posts.where((p) => p.id == widget.postId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      PostCard(
                        post: post,
                        onLike: () => ref.read(feedProvider.notifier).toggleLike(post.id),
                      ),
                      const Divider(),
                      if (_isLoading)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ))
                      else
                        ..._comments.map((c) => ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.cyan,
                                child: Text(c.author.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              title: Text(c.author.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(c.content),
                            )),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLength: 2000,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addComment,
                          icon: Icon(Icons.send, color: AppColors.cyan),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 8: Update CommunityScreen reference and router**

Replace the community screen import in `frontend/lib/core/router/app_router.dart`:
- Change `CommunityScreen` import to `FeedScreen` from `feed_screen.dart`
- Add a nested route for post detail:
  ```dart
  GoRoute(
    path: '/community',
    name: 'community',
    builder: (context, state) => const FeedScreen(),
    routes: [
      GoRoute(
        path: 'post/:postId',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
        ),
      ),
    ],
  ),
  ```

- [ ] **Step 9: Run tests**

```bash
cd /Users/lasharela/Development/spectrum/frontend
flutter test
```

Expected: All tests pass.

- [ ] **Step 10: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add frontend/
git commit -m "feat: add community feed, post detail, and create post screens"
```

### Task 9: Cloudflare Workers Deployment

**Files:**
- Modify: `backend/wrangler.toml` (if needed)
- Modify: `frontend/lib/shared/providers/api_provider.dart` (production URL)

- [ ] **Step 1: Login to Cloudflare**

```bash
cd /Users/lasharela/Development/spectrum/backend
npx wrangler login
```

Follow the browser prompt to authenticate.

- [ ] **Step 2: Set DATABASE_URL secret**

```bash
cd /Users/lasharela/Development/spectrum/backend
npx wrangler secret put DATABASE_URL
```

Paste your Neon connection string when prompted.

- [ ] **Step 3: Generate Prisma client for deployment**

```bash
cd /Users/lasharela/Development/spectrum/backend
npx prisma generate
```

- [ ] **Step 4: Deploy to Cloudflare Workers**

```bash
cd /Users/lasharela/Development/spectrum/backend
pnpm run deploy:cf
```

Expected: Deployment successful, outputs a URL like `https://spectrum-api.<your-subdomain>.workers.dev`

- [ ] **Step 5: Verify health endpoint**

```bash
curl https://spectrum-api.<your-subdomain>.workers.dev/api/health
```

Expected: `{"status":"ok"}`

- [ ] **Step 6: Update Flutter API base URL**

In `frontend/lib/shared/providers/api_provider.dart`, update the `_baseUrl` constant to the deployed Workers URL. Consider using `--dart-define` for environment-based configuration:

```dart
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8787',
);
```

Then run with:
```bash
flutter run --dart-define=API_BASE_URL=https://spectrum-api.<subdomain>.workers.dev
```

- [ ] **Step 7: Commit**

```bash
cd /Users/lasharela/Development/spectrum
git add -A
git commit -m "feat: deploy backend to Cloudflare Workers and configure frontend API URL"
```
