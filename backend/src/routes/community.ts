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

  // GET / - list posts (paginated)
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
        tags: JSON.parse(p.tags),
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

  // POST / - create a post
  app.post("/", zValidator("json", createPostSchema), async (c) => {
    const { content, tags } = c.req.valid("json");
    const user = c.get("user");
    const prisma = c.get("prisma");

    const post = await prisma.post.create({
      data: { content, tags: JSON.stringify(tags), authorId: user.id },
      include: {
        author: { select: { id: true, name: true, image: true, userType: true } },
      },
    });

    return c.json(
      {
        post: {
          id: post.id,
          content: post.content,
          tags: JSON.parse(post.tags),
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

  // GET /:id - get single post
  app.get("/:id", async (c) => {
    const id = c.req.param("id");
    const user = c.get("user");
    const prisma = c.get("prisma");

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
        tags: JSON.parse(post.tags),
        authorId: post.authorId,
        author: post.author,
        createdAt: post.createdAt.toISOString(),
        likesCount: post.likesCount,
        commentsCount: post.commentsCount,
        liked: post.reactions.length > 0,
      },
    });
  });

  // DELETE /:id - delete own post
  app.delete("/:id", async (c) => {
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

  // GET /:id/comments - list comments (paginated)
  app.get("/:id/comments", async (c) => {
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
  app.post("/:id/comments", zValidator("json", createCommentSchema), async (c) => {
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
  app.delete("/:id/comments/:commentId", async (c) => {
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
  app.put("/:id/reactions", async (c) => {
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
  app.delete("/:id/reactions", async (c) => {
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
