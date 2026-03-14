import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import type { AppBindings, AppVariables } from "../types/context.js";
import { sessionMiddleware, optionalSessionMiddleware } from "../middleware/session.js";

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(5000),
  imageUrl: z.string().url().optional(),
  tags: z
    .array(z.string().max(30))
    .max(5)
    .default([]),
  category: z.string().default("General"),
});

const updatePostSchema = z.object({
  title: z.string().max(200).optional(),
  content: z.string().min(1).max(5000).optional(),
  imageUrl: z.string().url().nullable().optional(),
  tags: z.array(z.string().max(30)).max(5).optional(),
  category: z.string().optional(),
});

const createCommentSchema = z.object({
  content: z.string().min(1).max(2000),
});

const paginationSchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(50).default(20),
  q: z.string().optional(),
  category: z.string().optional(),
  authorId: z.string().optional(),
  state: z.string().max(100).optional(),
  city: z.string().max(100).optional(),
});

export function communityRoutes() {
  const app = new Hono<{ Bindings: AppBindings; Variables: AppVariables }>();

  // GET / - list posts (paginated, public read)
  app.get("/", optionalSessionMiddleware, async (c) => {
    const prisma = c.get("prisma");
    const { cursor, limit, q, category, authorId, state, city } = paginationSchema.parse({
      cursor: c.req.query("cursor"),
      limit: c.req.query("limit"),
      q: c.req.query("q"),
      category: c.req.query("category"),
      authorId: c.req.query("authorId"),
      state: c.req.query("state"),
      city: c.req.query("city"),
    });

    const user = c.get("user") as any;

    const where: Record<string, unknown> = {};
    if (q) {
      where.OR = [
        { title: { contains: q } },
        { content: { contains: q } },
      ];
    }
    if (category) {
      where.category = category;
    }
    if (authorId) {
      where.authorId = authorId;
    }
    if (state) {
      where.author = { is: { state } };
    }
    if (city) {
      where.author = { is: { ...(where.author as any)?.is, city } };
    }

    const posts = await prisma.post.findMany({
      where,
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { createdAt: "desc" },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? { reactions: { where: { authorId: user.id }, select: { id: true } } } : {}),
      },
    });

    const hasMore = posts.length > limit;
    const results = hasMore ? posts.slice(0, limit) : posts;
    const nextCursor = hasMore ? results[results.length - 1].id : null;

    return c.json({
      posts: results.map((p) => ({
        id: p.id,
        title: p.title,
        content: p.content,
        imageUrl: p.imageUrl,
        tags: JSON.parse(p.tags),
        category: p.category,
        authorId: p.authorId,
        author: p.author,
        createdAt: p.createdAt.toISOString(),
        likesCount: p.likesCount,
        commentsCount: p.commentsCount,
        liked: ((p as any).reactions?.length ?? 0) > 0,
      })),
      nextCursor,
    });
  });

  // POST / - create a post
  app.post("/", sessionMiddleware, zValidator("json", createPostSchema), async (c) => {
    const { title, content, imageUrl, tags, category } = c.req.valid("json");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const post = await prisma.post.create({
      data: { title, content, imageUrl, tags: JSON.stringify(tags), category, authorId: user.id },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
      },
    });

    return c.json(
      {
        post: {
          id: post.id,
          title: post.title,
          content: post.content,
          imageUrl: post.imageUrl,
          tags: JSON.parse(post.tags),
          category: post.category,
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

  // GET /:id - get single post (public read)
  app.get("/:id", optionalSessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const post = await prisma.post.findUnique({
      where: { id },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
        ...(user ? { reactions: { where: { authorId: user.id }, select: { id: true } } } : {}),
      },
    });

    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    return c.json({
      post: {
        id: post.id,
        title: post.title,
        content: post.content,
        imageUrl: post.imageUrl,
        tags: JSON.parse(post.tags),
        category: post.category,
        authorId: post.authorId,
        author: post.author,
        createdAt: post.createdAt.toISOString(),
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        liked: ((post as any).reactions?.length ?? 0) > 0,
      },
    });
  });

  // PUT /:id - update own post
  app.put("/:id", sessionMiddleware, zValidator("json", updatePostSchema), async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");
    const body = c.req.valid("json");

    const post = await prisma.post.findUnique({ where: { id } });

    if (!post) {
      return c.json({ error: "Post not found", code: "NOT_FOUND" }, 404);
    }

    if (post.authorId !== user.id) {
      return c.json({ error: "Not authorized", code: "FORBIDDEN" }, 403);
    }

    const updated = await prisma.post.update({
      where: { id },
      data: {
        ...(body.title !== undefined ? { title: body.title } : {}),
        ...(body.content !== undefined ? { content: body.content } : {}),
        ...(body.imageUrl !== undefined ? { imageUrl: body.imageUrl } : {}),
        ...(body.tags !== undefined ? { tags: JSON.stringify(body.tags) } : {}),
        ...(body.category !== undefined ? { category: body.category } : {}),
      },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
        reactions: { where: { authorId: user.id }, select: { id: true } },
      },
    });

    return c.json({
      post: {
        id: updated.id,
        title: updated.title,
        content: updated.content,
        imageUrl: updated.imageUrl,
        tags: JSON.parse(updated.tags),
        category: updated.category,
        authorId: updated.authorId,
        author: updated.author,
        createdAt: updated.createdAt.toISOString(),
        likesCount: updated.likesCount,
        commentsCount: updated.commentsCount,
        liked: updated.reactions.length > 0,
      },
    });
  });

  // DELETE /:id - delete own post
  app.delete("/:id", sessionMiddleware, async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

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

  // GET /:id/comments - list comments (paginated, public read)
  app.get("/:id/comments", optionalSessionMiddleware, async (c) => {
    const postId = c.req.param("id");
    const prisma = c.get("prisma");
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

  // POST /:id/comments - add comment
  app.post("/:id/comments", sessionMiddleware, zValidator("json", createCommentSchema), async (c) => {
    const postId = c.req.param("id");
    const { content } = c.req.valid("json");
    const user = c.get("user");
    const prisma = c.get("prisma");

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

  // DELETE /:id/comments/:commentId - delete own comment
  app.delete("/:id/comments/:commentId", sessionMiddleware, async (c) => {
    const postId = c.req.param("id");
    const commentId = c.req.param("commentId");
    const user = c.get("user");
    const prisma = c.get("prisma");

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

  // PUT /:id/reactions - like a post
  app.put("/:id/reactions", sessionMiddleware, async (c) => {
    const postId = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

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

  // DELETE /:id/reactions - unlike a post
  app.delete("/:id/reactions", sessionMiddleware, async (c) => {
    const postId = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

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
