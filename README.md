# LiveStore

LiveStore is a self-hosted open source Phoenix LiveView e-commerce store.

  * Stripe for payment processing
  * Sendgrid for emails
  * PostgreSQL
  * Vix (Vips NIF) for image processing

Images are uploaded to and hosted from the server, by default in the `/uploads` directory in the root of the project.

## Configuration

The following env vars can be set:
```
STRIPE_SECRET="sk_xxx..."
STRIPE_PUBLIC="pk_xxx..."
STRIPE_WEBHOOK_SECRET="whsec_xxx..."
SENDGRID_API_KEY="SG.xxx..."
DATABASE_URL="ecto://..."
UPLOADS_DIR="/var/my_live_store/uploads/"
PHX_HOST="..."
PHX_SERVER="true"
PORT="4000"
SECRET_KEY_BASE="..."
```

LiveStore assumes you have SendGrid and Stripe accounts set up.

LiveStore also assumes you're running behind a reverse proxy like Nginx for handling TLS.
If you want to do it natively, you may wish to set things up yourself in `config/runtime.exs`.

### Store Settings

Store configuration like store name, store subtitle, home page background image, favicon, flat-rate shipping cost, etc. 
is contained in an ETS table and is synced to disk in a file named `live_store_config.tab` in the root of the project 
every time you make a change in the app.

You can also read or write the config values from the command line with mix tasks or release tasks:

```
# Mix tasks
MIX_ENV=prod mix livestore.config # This prints all config values and their defaults
MIX_ENV=prod mix livestore.config "store_name" "My Live Store" # This sets a config value

# Release tasks (from a running release without access to Mix)
bin/live_store eval "LiveStore.ReleaseTasks.config()"
bin/live_store eval "LiveStore.ReleaseTasks.change_config(:store_name, \"My Live Store\")"
```

The image ones are URLs, so either `"/uploads/my_file_name.jpg"`, always prefixed with `/uploads/`, or a full external URL of an image.
It's much easier to set these from the app via uploading an image.

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

### Logging in

If this is your first account and you haven't configured your sender email, you'll need to do one of two things to login:

Generate a login url:
```
# mix task
MIX_ENV=prod mix livestore.login "myname@example.com"

# or, release task
bin/live_store eval "LiveStore.ReleaseTasks.login(\"myname@example.com\")"
```

OR

Configure the email from the command line:
```
# mix task
MIX_ENV=prod mix livestore.config "store_email" "sales@mystore.com"

# or, release task
bin/live_store eval "LiveStore.ReleaseTasks.change_config(\"store_email\", \"sales@mystore.com\")"
```
Then you can login through the app (via email) since you've set the `store_email` config item to your Sendgrid verified sender.

## Running

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
