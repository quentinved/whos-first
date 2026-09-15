/// Who's First does not talk to a server. This Worker exists only because App Store Connect
/// will not accept a listing without a public privacy policy URL and a public support URL.
///
/// Nothing here reads a request body, sets a cookie, or writes anything down. It serves two
/// pages and 404s everything else.
import { privacyPage } from "./privacy.ts";
import { supportPage } from "./support.ts";

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.split("/").filter(Boolean).join("/");
    if (request.method === "GET" && path === "privacy") return privacyPage();
    if (request.method === "GET" && path === "support") return supportPage();
    // A bare visit should land somewhere useful rather than on an error.
    if (request.method === "GET" && path === "") {
      return Response.redirect(new URL("/support", url).toString(), 302);
    }
    return new Response("not found", { status: 404, headers: { "content-type": "text/plain; charset=utf-8" } });
  },
};
