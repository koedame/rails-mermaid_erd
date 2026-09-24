# Security Policy

## Reporting a vulnerability

Please report security problems privately through
[GitHub's private vulnerability reporting](https://github.com/koedame/rails-mermaid_erd/security/advisories/new).
Do not open a public issue for them.

## Supported versions

Security fixes are released for the latest version only.

## What counts as a vulnerability

rails-mermaid_erd reads your application's models and database metadata and
writes one self-contained HTML file. We treat these as vulnerabilities:

- Metadata from your app (table or column names, comments, `config/mermaid_erd.yml`)
  that runs script or injects markup when the generated HTML is opened.
- The generated HTML loading anything from the network. Every script it needs
  is inlined into the file.

The generated file contains your schema, including comments. Share it the way
you would share the schema itself.
