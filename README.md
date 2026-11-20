# rota-x

Door rotas for head doormen. Pick who's working each night, set the hours, and send the week to the area manager as an image, Excel file or message.

- Installable web app (PWA) with offline support, light and dark mode
- Every head doorman signs in with an account; rotas are kept on the phone for offline use and synced to Supabase
- Plain static site: no build step. `index.html` holds the whole app; `vendor/` holds the Supabase and SheetJS libraries

## Admin dashboard

`/admin.html` shows every venue, a person search with previous and upcoming shifts, and venue tabs with each venue's rota and staff. It's read-only and only opens for accounts listed in the `admins` table (see `supabase/setup.sql`).

## Supabase

`supabase/setup.sql` creates the `venues`, `staff` and `shifts` tables with row-level security so each account only sees its own venue. The project URL and publishable key are set at the top of the sync section in `index.html`.

In Supabase → Authentication → URL Configuration, set the Site URL and a Redirect URL to the deployed address so confirmation and password-reset emails link back to the app.
