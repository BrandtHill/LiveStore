# LiveStore

LiveStore is a self-hosted open source Phoenix LiveView e-commerce store.

  * Stripe for payment processing
  * Sendgrid for emails
  * PostgreSQL
  * Vix (Vips NIF) for image processing

Images are uploaded to and hosted from the server.

## Configuration

The following env vars can be set:
```
STRIPE_SECRET="sk_xxx..."
STRIPE_PUBLIC="pk_xxx..."
STRIPE_WEBHOOK_SECRET="whsec_xxx..."
SENDGRID_API_KEY="SG.xxx..."
DATABASE_URL="ecto://..."
PHX_HOST="..."
PHX_SERVER="true"
PORT="4000"
```

LiveStore assumes you have SendGrid and Stripe accounts set up.

LiveStore also assumes you're running behind a reverse proxy like Nginx for handling TLS.
If you want to do it natively, you may wish to set things up yourself in `config/runtime.exs`.

### Store Settings

Store configuration like store name, store subtitle, home page background image, favicon, flat-rate shipping cost, etc. 
is contained in an ETS table and is synced to disk in a file named `live_store_config.tab` in the root of this repo 
every time you make a change in the app.

## Admin

You must be an admin to change store settings, add products, and fulfill orders.

Run the following mix task:

```
MIX_ENV=prod mix livestore.admin "myname@example.com"
```

Or if in a release:

```
bin/live_store eval "LiveStore.ReleaseTasks.make_admin(\"myname@example.com\")"
```

Once you login to an admin account you'll see the items that allow you perform admin actions.

## Running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
