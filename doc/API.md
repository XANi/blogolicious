## API

unless stated otherwise, every endpoint answers in plaintext/html or JSON, depending on Accept headers.
API is mostly to facilitate updates via jquery instead of full page reloads

### Post a comment
    POST /blog/comments/new

Posts a comment. Parameters:

 * **postid** - id of the post
 * **author** - author nameauthor':'dasdasd',
 * **email** - author email
 * **url** (optional) - author's page url
 * **comment** - comment's content

### Get comments for a blogpost (WiP)

    GET /blog/post/2014-12-29/comments

