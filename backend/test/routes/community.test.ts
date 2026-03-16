import { describe, it, expect, beforeEach } from "vitest";
import app from "../../src/index.js";
import { cleanDatabase, prisma } from "../setup.js";

const dbAvailable = !!prisma;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Create a user + session directly in the DB for test auth. */
async function createTestUser(
  overrides: Partial<{
    firstName: string;
    lastName: string;
    state: string;
    city: string;
    userType: string;
  }> = {}
) {
  const uid = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const user = await prisma!.user.create({
    data: {
      email: `test-${uid}@test.com`,
      name: `${overrides.firstName ?? "Test"} ${overrides.lastName ?? "User"}`,
      firstName: overrides.firstName ?? "Test",
      lastName: overrides.lastName ?? "User",
      userType: overrides.userType ?? "parent",
      state: overrides.state,
      city: overrides.city,
      emailVerified: false,
    },
  });

  const session = await prisma!.session.create({
    data: {
      userId: user.id,
      token: `test-token-${uid}`,
      expiresAt: new Date(Date.now() + 86_400_000),
    },
  });

  return { user, token: session.token };
}

function authHeaders(token: string): Record<string, string> {
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

/** Convenience: create a post via the API and return the parsed JSON body. */
async function createPost(
  token: string,
  data?: Partial<{
    title: string;
    content: string;
    category: string;
    tags: string[];
    imageUrl: string;
  }>
) {
  const res = await app.request("/api/posts", {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({
      title: data?.title ?? "Test Post",
      content: data?.content ?? "Test content for the post",
      category: data?.category ?? "General",
      ...(data?.tags ? { tags: data.tags } : {}),
      ...(data?.imageUrl ? { imageUrl: data.imageUrl } : {}),
    }),
  });
  return { res, body: (await res.json()) as any };
}

/** Convenience: create a comment via the API. */
async function createComment(
  token: string,
  postId: string,
  content?: string
) {
  const res = await app.request(`/api/posts/${postId}/comments`, {
    method: "POST",
    headers: authHeaders(token),
    body: JSON.stringify({ content: content ?? "A test comment" }),
  });
  return { res, body: (await res.json()) as any };
}

/** Like a post via the API. */
async function likePost(token: string, postId: string) {
  const res = await app.request(`/api/posts/${postId}/reactions`, {
    method: "PUT",
    headers: authHeaders(token),
  });
  return { res, body: (await res.json()) as any };
}

/** Unlike a post via the API. */
async function unlikePost(token: string, postId: string) {
  const res = await app.request(`/api/posts/${postId}/reactions`, {
    method: "DELETE",
    headers: authHeaders(token),
  });
  return { res, body: (await res.json()) as any };
}

// ---------------------------------------------------------------------------
// Posts API
// ---------------------------------------------------------------------------

describe("Posts API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // ---- POST /api/posts ----
  describe("POST /api/posts", () => {
    it.skipIf(!dbAvailable)(
      "should create a post with content and tags",
      async () => {
        const { token } = await createTestUser();
        const { res, body } = await createPost(token, {
          title: "My First Post",
          content: "Hello world!",
          tags: ["autism", "community"],
          category: "General",
        });

        expect(res.status).toBe(201);
        expect(body.post).toBeDefined();
        expect(body.post.title).toBe("My First Post");
        expect(body.post.content).toBe("Hello world!");
        expect(body.post.tags).toEqual(["autism", "community"]);
        expect(body.post.category).toBe("General");
        expect(body.post.likesCount).toBe(0);
        expect(body.post.commentsCount).toBe(0);
        expect(body.post.liked).toBe(false);
        expect(body.post.author).toBeDefined();
        expect(body.post.author.name).toBe("Test User");
        expect(body.post.id).toBeDefined();
        expect(body.post.createdAt).toBeDefined();
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject post with empty content",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/posts", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "A title",
            content: "",
            category: "General",
          }),
        });

        // Zod validation should reject empty content (min 1)
        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject post with content > 5000 chars",
      async () => {
        const { token } = await createTestUser();
        const longContent = "x".repeat(5001);
        const res = await app.request("/api/posts", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "A title",
            content: longContent,
            category: "General",
          }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject post with > 5 tags",
      async () => {
        const { token } = await createTestUser();
        const res = await app.request("/api/posts", {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({
            title: "Too many tags",
            content: "Some content",
            tags: ["a", "b", "c", "d", "e", "f"],
          }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject unauthenticated request with 401",
      async () => {
        const res = await app.request("/api/posts", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            title: "No auth",
            content: "Should fail",
          }),
        });

        expect(res.status).toBe(401);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authenticated");
        expect(body.code).toBe("UNAUTHORIZED");
      }
    );
  });

  // ---- GET /api/posts ----
  describe("GET /api/posts", () => {
    it.skipIf(!dbAvailable)(
      "should return paginated posts with author info",
      async () => {
        const { token } = await createTestUser();
        // Create two posts
        await createPost(token, { title: "Post A", content: "Content A" });
        await createPost(token, { title: "Post B", content: "Content B" });

        const res = await app.request("/api/posts", { method: "GET" });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.posts).toBeDefined();
        expect(Array.isArray(body.posts)).toBe(true);
        expect(body.posts.length).toBe(2);
        // Most recent first
        expect(body.posts[0].title).toBe("Post B");
        expect(body.posts[1].title).toBe("Post A");
        // Author info included
        expect(body.posts[0].author).toBeDefined();
        expect(body.posts[0].author.id).toBeDefined();
        expect(body.posts[0].author.name).toBeDefined();
        // nextCursor should be null since there are only 2 posts (< default limit 20)
        expect(body.nextCursor).toBeNull();
      }
    );

    it.skipIf(!dbAvailable)(
      "should paginate with cursor",
      async () => {
        const { token } = await createTestUser();
        // Create 3 posts; request with limit=2 to trigger pagination
        await createPost(token, { title: "Post 1", content: "C1" });
        await createPost(token, { title: "Post 2", content: "C2" });
        await createPost(token, { title: "Post 3", content: "C3" });

        // First page
        const res1 = await app.request("/api/posts?limit=2", {
          method: "GET",
        });
        expect(res1.status).toBe(200);
        const page1 = (await res1.json()) as any;
        expect(page1.posts.length).toBe(2);
        expect(page1.nextCursor).toBeDefined();
        expect(page1.nextCursor).not.toBeNull();

        // Second page using cursor
        const res2 = await app.request(
          `/api/posts?limit=2&cursor=${page1.nextCursor}`,
          { method: "GET" }
        );
        expect(res2.status).toBe(200);
        const page2 = (await res2.json()) as any;
        expect(page2.posts.length).toBe(1);
        expect(page2.nextCursor).toBeNull();

        // No overlap between pages
        const allIds = [
          ...page1.posts.map((p: any) => p.id),
          ...page2.posts.map((p: any) => p.id),
        ];
        expect(new Set(allIds).size).toBe(3);
      }
    );

    it.skipIf(!dbAvailable)(
      "should include liked status for current user",
      async () => {
        const { token, user } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Likeable",
          content: "Like me",
        });
        const postId = created.post.id;

        // Like the post
        await likePost(token, postId);

        // Fetch posts with auth header — liked should be true
        const res = await app.request("/api/posts", {
          method: "GET",
          headers: { Authorization: `Bearer ${token}` },
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        const post = body.posts.find((p: any) => p.id === postId);
        expect(post).toBeDefined();
        expect(post.liked).toBe(true);
      }
    );

    it.skipIf(!dbAvailable)(
      "should filter posts by search query ?q=",
      async () => {
        const { token } = await createTestUser();
        await createPost(token, {
          title: "Flutter tips",
          content: "Use Riverpod for state",
        });
        await createPost(token, {
          title: "Cooking recipes",
          content: "Pasta is great",
        });

        const res = await app.request("/api/posts?q=Flutter", {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.posts.length).toBe(1);
        expect(body.posts[0].title).toBe("Flutter tips");
      }
    );

    it.skipIf(!dbAvailable)(
      "should not return soft-deleted posts in list",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Will be soft-deleted",
          content: "Hidden post",
        });
        const postId = created.post.id;

        // Soft-delete directly in DB
        await prisma!.post.update({
          where: { id: postId },
          data: { deletedAt: new Date() },
        });

        const res = await app.request("/api/posts", { method: "GET" });
        const body = (await res.json()) as any;
        const ids = body.posts.map((p: any) => p.id);
        expect(ids).not.toContain(postId);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for soft-deleted post by ID",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Soft-deleted detail",
          content: "Should 404",
        });
        const postId = created.post.id;

        await prisma!.post.update({
          where: { id: postId },
          data: { deletedAt: new Date() },
        });

        const res = await app.request(`/api/posts/${postId}`, { method: "GET" });
        expect(res.status).toBe(404);
      }
    );
  });

  // ---- GET /api/posts/:id ----
  describe("GET /api/posts/:id", () => {
    it.skipIf(!dbAvailable)(
      "should return single post",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Solo Post",
          content: "Detailed content here",
          category: "Education",
        });
        const postId = created.post.id;

        const res = await app.request(`/api/posts/${postId}`, {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.post).toBeDefined();
        expect(body.post.id).toBe(postId);
        expect(body.post.title).toBe("Solo Post");
        expect(body.post.content).toBe("Detailed content here");
        expect(body.post.category).toBe("Education");
        expect(body.post.author).toBeDefined();
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent post",
      async () => {
        // We need a valid request that passes the middleware — create a user
        // so the middleware has DB bindings, but use a non-existent post ID.
        // Actually, GET /:id uses optionalSession, so no auth needed — but we
        // still need DB bindings to work. With prisma available the app should
        // route through properly.
        const res = await app.request("/api/posts/non-existent-id-12345", {
          method: "GET",
        });
        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Post not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // ---- PUT /api/posts/:id ----
  describe("PUT /api/posts/:id", () => {
    it.skipIf(!dbAvailable)(
      "should update own post content and category",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Original Title",
          content: "Original",
          category: "General",
        });
        const postId = created.post.id;

        const res = await app.request(`/api/posts/${postId}`, {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({
            content: "Updated content",
            category: "Education",
          }),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.post.content).toBe("Updated content");
        expect(body.post.category).toBe("Education");
        // Title should remain unchanged
        expect(body.post.title).toBe("Original Title");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 when updating another user's post",
      async () => {
        const author = await createTestUser({ firstName: "Author" });
        const other = await createTestUser({ firstName: "Other" });
        const { body: created } = await createPost(author.token, {
          title: "Author Post",
          content: "Owned by author",
        });
        const postId = created.post.id;

        const res = await app.request(`/api/posts/${postId}`, {
          method: "PUT",
          headers: authHeaders(other.token),
          body: JSON.stringify({ content: "Hacked" }),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent post",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request("/api/posts/non-existent-id-12345", {
          method: "PUT",
          headers: authHeaders(token),
          body: JSON.stringify({ content: "Nope" }),
        });

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Post not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // ---- DELETE /api/posts/:id ----
  describe("DELETE /api/posts/:id", () => {
    it.skipIf(!dbAvailable)(
      "should delete own post",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Deletable",
          content: "Will be removed",
        });
        const postId = created.post.id;

        const res = await app.request(`/api/posts/${postId}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify it's actually gone
        const check = await app.request(`/api/posts/${postId}`, {
          method: "GET",
        });
        expect(check.status).toBe(404);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 when deleting another user's post",
      async () => {
        const author = await createTestUser({ firstName: "Author" });
        const other = await createTestUser({ firstName: "Other" });
        const { body: created } = await createPost(author.token, {
          title: "Not yours",
          content: "Hands off",
        });

        const res = await app.request(`/api/posts/${created.post.id}`, {
          method: "DELETE",
          headers: authHeaders(other.token),
        });

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );

    it.skipIf(!dbAvailable)(
      "should cascade delete comments and reactions",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Cascade test",
          content: "Will be deleted with children",
        });
        const postId = created.post.id;

        // Add a comment and a reaction
        await createComment(token, postId, "A comment on this post");
        await likePost(token, postId);

        // Verify comment and reaction exist
        const commentsBefore = await prisma!.comment.findMany({
          where: { postId },
        });
        const reactionsBefore = await prisma!.reaction.findMany({
          where: { postId },
        });
        expect(commentsBefore.length).toBe(1);
        expect(reactionsBefore.length).toBe(1);

        // Delete the post
        const res = await app.request(`/api/posts/${postId}`, {
          method: "DELETE",
          headers: authHeaders(token),
        });
        expect(res.status).toBe(200);

        // Verify cascade — comments and reactions should be gone
        const commentsAfter = await prisma!.comment.findMany({
          where: { postId },
        });
        const reactionsAfter = await prisma!.reaction.findMany({
          where: { postId },
        });
        expect(commentsAfter.length).toBe(0);
        expect(reactionsAfter.length).toBe(0);
      }
    );
  });
});

// ---------------------------------------------------------------------------
// Comments API
// ---------------------------------------------------------------------------

describe("Comments API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // ---- POST /api/posts/:id/comments ----
  describe("POST /api/posts/:id/comments", () => {
    it.skipIf(!dbAvailable)(
      "should create a comment and increment commentsCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Commentable",
          content: "Leave a comment",
        });
        const postId = created.post.id;
        expect(created.post.commentsCount).toBe(0);

        const { res, body } = await createComment(
          token,
          postId,
          "Great post!"
        );

        expect(res.status).toBe(201);
        expect(body.comment).toBeDefined();
        expect(body.comment.content).toBe("Great post!");
        expect(body.comment.postId).toBe(postId);
        expect(body.comment.author).toBeDefined();
        expect(body.comment.createdAt).toBeDefined();

        // Verify commentsCount incremented on the post
        const postRes = await app.request(`/api/posts/${postId}`, {
          method: "GET",
        });
        const postBody = (await postRes.json()) as any;
        expect(postBody.post.commentsCount).toBe(1);
      }
    );

    it.skipIf(!dbAvailable)(
      "should reject comment with content > 2000 chars",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Post",
          content: "Content",
        });
        const postId = created.post.id;

        const longContent = "y".repeat(2001);
        const res = await app.request(`/api/posts/${postId}/comments`, {
          method: "POST",
          headers: authHeaders(token),
          body: JSON.stringify({ content: longContent }),
        });

        expect(res.status).toBe(400);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 404 for non-existent post",
      async () => {
        const { token } = await createTestUser();

        const res = await app.request(
          "/api/posts/non-existent-post-id/comments",
          {
            method: "POST",
            headers: authHeaders(token),
            body: JSON.stringify({ content: "Orphan comment" }),
          }
        );

        expect(res.status).toBe(404);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Post not found");
        expect(body.code).toBe("NOT_FOUND");
      }
    );
  });

  // ---- GET /api/posts/:id/comments ----
  describe("GET /api/posts/:id/comments", () => {
    it.skipIf(!dbAvailable)(
      "should return paginated comments with author info",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "With comments",
          content: "Read the comments",
        });
        const postId = created.post.id;

        // Create a couple of comments
        await createComment(token, postId, "First comment");
        await createComment(token, postId, "Second comment");

        const res = await app.request(`/api/posts/${postId}/comments`, {
          method: "GET",
        });

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.comments).toBeDefined();
        expect(Array.isArray(body.comments)).toBe(true);
        expect(body.comments.length).toBe(2);
        // Each comment should have author info
        for (const comment of body.comments) {
          expect(comment.author).toBeDefined();
          expect(comment.author.id).toBeDefined();
          expect(comment.author.name).toBeDefined();
          expect(comment.content).toBeDefined();
          expect(comment.postId).toBe(postId);
          expect(comment.createdAt).toBeDefined();
        }
        // nextCursor should be null with only 2 comments
        expect(body.nextCursor).toBeNull();
      }
    );

    it.skipIf(!dbAvailable)(
      "should not return soft-deleted comments in list",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Post with comments",
          content: "Some will be soft-deleted",
        });
        const postId = created.post.id;

        const { body: commentBody } = await createComment(
          token,
          postId,
          "Visible comment"
        );
        const { body: deletedCommentBody } = await createComment(
          token,
          postId,
          "Hidden comment"
        );
        const deletedCommentId = deletedCommentBody.comment.id;

        // Soft-delete one comment directly in DB
        await prisma!.comment.update({
          where: { id: deletedCommentId },
          data: { deletedAt: new Date() },
        });

        const res = await app.request(`/api/posts/${postId}/comments`, {
          method: "GET",
        });
        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.comments.length).toBe(1);
        expect(body.comments[0].content).toBe("Visible comment");
        const ids = body.comments.map((c: any) => c.id);
        expect(ids).not.toContain(deletedCommentId);
      }
    );
  });

  // ---- DELETE /api/posts/:id/comments/:commentId ----
  describe("DELETE /api/posts/:id/comments/:commentId", () => {
    it.skipIf(!dbAvailable)(
      "should delete own comment and decrement commentsCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Has comment",
          content: "Comment then delete",
        });
        const postId = created.post.id;

        const { body: commentBody } = await createComment(
          token,
          postId,
          "Temporary comment"
        );
        const commentId = commentBody.comment.id;

        // Verify commentsCount is 1
        const postBefore = await app.request(`/api/posts/${postId}`, {
          method: "GET",
        });
        const postBodyBefore = (await postBefore.json()) as any;
        expect(postBodyBefore.post.commentsCount).toBe(1);

        // Delete the comment
        const res = await app.request(
          `/api/posts/${postId}/comments/${commentId}`,
          { method: "DELETE", headers: authHeaders(token) }
        );

        expect(res.status).toBe(200);
        const body = (await res.json()) as any;
        expect(body.success).toBe(true);

        // Verify commentsCount decremented
        const postAfter = await app.request(`/api/posts/${postId}`, {
          method: "GET",
        });
        const postBodyAfter = (await postAfter.json()) as any;
        expect(postBodyAfter.post.commentsCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should return 403 when deleting another user's comment",
      async () => {
        const commenter = await createTestUser({ firstName: "Commenter" });
        const other = await createTestUser({ firstName: "Other" });
        const { body: created } = await createPost(commenter.token, {
          title: "Post",
          content: "Content",
        });
        const postId = created.post.id;

        const { body: commentBody } = await createComment(
          commenter.token,
          postId,
          "My comment"
        );
        const commentId = commentBody.comment.id;

        // Other user tries to delete commenter's comment
        const res = await app.request(
          `/api/posts/${postId}/comments/${commentId}`,
          { method: "DELETE", headers: authHeaders(other.token) }
        );

        expect(res.status).toBe(403);
        const body = (await res.json()) as any;
        expect(body.error).toBe("Not authorized");
        expect(body.code).toBe("FORBIDDEN");
      }
    );
  });
});

// ---------------------------------------------------------------------------
// Reactions API
// ---------------------------------------------------------------------------

describe("Reactions API", () => {
  beforeEach(async () => {
    await cleanDatabase();
  });

  // ---- PUT /api/posts/:id/reactions ----
  describe("PUT /api/posts/:id/reactions", () => {
    it.skipIf(!dbAvailable)(
      "should like a post and increment likesCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Likeable",
          content: "Like this",
        });
        const postId = created.post.id;
        expect(created.post.likesCount).toBe(0);

        const { res, body } = await likePost(token, postId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(true);
        expect(body.likesCount).toBe(1);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent (liking twice returns same count)",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Double like",
          content: "Like twice",
        });
        const postId = created.post.id;

        // Like once
        const first = await likePost(token, postId);
        expect(first.body.liked).toBe(true);
        expect(first.body.likesCount).toBe(1);

        // Like again — should be idempotent
        const second = await likePost(token, postId);
        expect(second.body.liked).toBe(true);
        expect(second.body.likesCount).toBe(1);
      }
    );
  });

  // ---- DELETE /api/posts/:id/reactions ----
  describe("DELETE /api/posts/:id/reactions", () => {
    it.skipIf(!dbAvailable)(
      "should unlike a post and decrement likesCount",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Unlikeable",
          content: "Like then unlike",
        });
        const postId = created.post.id;

        // Like first
        await likePost(token, postId);

        // Then unlike
        const { res, body } = await unlikePost(token, postId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(false);
        expect(body.likesCount).toBe(0);
      }
    );

    it.skipIf(!dbAvailable)(
      "should be idempotent (unliking when not liked returns same count)",
      async () => {
        const { token } = await createTestUser();
        const { body: created } = await createPost(token, {
          title: "Never liked",
          content: "Cannot unlike what is not liked",
        });
        const postId = created.post.id;

        // Unlike without having liked — should be idempotent
        const { res, body } = await unlikePost(token, postId);

        expect(res.status).toBe(200);
        expect(body.liked).toBe(false);
        expect(body.likesCount).toBe(0);
      }
    );
  });
});
