defmodule LiveStore.Config do
  @table :live_store_config
  @filename ~c"live_store_config.tab"

  require Logger

  import Ecto.Changeset

  def init_table do
    case :ets.file2tab(@filename) do
      {:error, {:read_error, {:file_error, _file, :enoent}}} ->
        Logger.info("Config file for ETS table doesn't exist. Creating new table.")
        :ets.new(@table, [:named_table, :public, :set])

      {:error, {:read_error, {:file_error, _file, error}}} ->
        Logger.error("Got #{error} initializing Config ETS table from file. Creating new table.")
        :ets.new(@table, [:named_table, :public, :set])

      {:error, :cannot_create_table} ->
        Logger.error("Config ETS table already exists.")

      {:ok, @table} ->
        Logger.info("Config ETS table successfully read from file.")
    end
  end

  defp get(key, default) do
    :ets.lookup(@table, key)[key] || default
  end

  defp bulk_insert(values) do
    :ets.insert(@table, values)
    :ets.tab2file(@table, @filename)
  end

  # I could have created an Ecto embedded_schema, but I preferred generating functions for each field
  # at compile time. Making this module a struct would also make it seem like %Config{} structs could
  # created and passed around, but this is meant be a type of "singleton" pattern to borrow a term
  # from a lesser paradigm. Did you know you could use Ecto Changesets with a tuple of data map
  # and corresponding type map?

  @config_defaults %{
    store_name: "LiveStore",
    store_subtitle: "An open source Phoenix LiveView e-commerce store",
    store_email: "contact@example.com",
    shipping_countries: %{"US" => 500},
    favicon: "/favicon.ico",
    background_image:
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?ixlib=rb-4.0.3&auto=format&fit=crop&w=3540&q=80"
  }

  @config_keys Map.keys(@config_defaults)

  @config_types @config_keys
                |> Map.new(&{&1, :string})
                |> Map.merge(%{shipping_countries: {:map, :integer}})

  for {key, default} <- @config_defaults do
    escaped_default = Macro.escape(default)
    def unquote(key)(), do: get(unquote(key), unquote(escaped_default))
  end

  def config, do: Map.new(:ets.tab2list(@table))
  def defaults, do: @config_defaults

  def changeset(config, params \\ %{}) do
    {config, @config_types}
    |> cast(presanitize_params(params), @config_keys)
    |> validate_change(:shipping_countries, fn key, map ->
      if Enum.all?(map, fn {country, cost} ->
           country in available_country_codes() and cost >= 0
         end),
         do: [],
         else: [
           {key, "countries must be a valid 2 letter ISO code and costs must be greater than 0"}
         ]
    end)
  end

  # At this point, I have gone to some lengths to use Ecto changesets without using
  # Ecto schemas or embedded schemas at all, and I'm now storing weirdly shaped nested data in ETS.
  # This is handy for culling the extraneous fields that show up in Phoenix forms.
  defp presanitize_params(%{"shipping_countries" => %{} = map} = params) do
    Map.put(
      params,
      "shipping_countries",
      Map.reject(map, fn {k, _v} -> String.starts_with?(k, "_") end)
    )
  end

  defp presanitize_params(params), do: params

  def update(%{valid?: true} = changeset) do
    changeset.changes
    |> Enum.to_list()
    |> bulk_insert()
  end

  def update(changeset) do
    {:error, changeset}
  end

  @available_countries [
    {"US", "United States"},
    {"CA", "Canada"},
    {"GB", "United Kingdom"},
    {"AC", "Ascension Island"},
    {"AD", "Andorra"},
    {"AE", "United Arab Emirates"},
    {"AF", "Afghanistan"},
    {"AG", "Antigua and Barbuda"},
    {"AI", "Anguilla"},
    {"AL", "Albania"},
    {"AM", "Armenia"},
    {"AO", "Angola"},
    {"AQ", "Antarctica"},
    {"AR", "Argentina"},
    {"AT", "Austria"},
    {"AU", "Australia"},
    {"AW", "Aruba"},
    {"AX", "Åland Islands"},
    {"AZ", "Azerbaijan"},
    {"BA", "Bosnia and Herzegovina"},
    {"BB", "Barbados"},
    {"BD", "Bangladesh"},
    {"BE", "Belgium"},
    {"BF", "Burkina Faso"},
    {"BG", "Bulgaria"},
    {"BH", "Bahrain"},
    {"BI", "Burundi"},
    {"BJ", "Benin"},
    {"BL", "Saint Barthélemy"},
    {"BM", "Bermuda"},
    {"BN", "Brunei"},
    {"BO", "Bolivia"},
    {"BQ", "Caribbean Netherlands"},
    {"BR", "Brazil"},
    {"BS", "Bahamas"},
    {"BT", "Bhutan"},
    {"BV", "Bouvet Island"},
    {"BW", "Botswana"},
    {"BY", "Belarus"},
    {"BZ", "Belize"},
    {"CD", "Democratic Republic of the Congo"},
    {"CF", "Central African Republic"},
    {"CG", "Republic of the Congo"},
    {"CH", "Switzerland"},
    {"CI", "Côte d’Ivoire"},
    {"CK", "Cook Islands"},
    {"CL", "Chile"},
    {"CM", "Cameroon"},
    {"CN", "China"},
    {"CO", "Colombia"},
    {"CR", "Costa Rica"},
    {"CV", "Cape Verde"},
    {"CW", "Curaçao"},
    {"CY", "Cyprus"},
    {"CZ", "Czech Republic"},
    {"DE", "Germany"},
    {"DJ", "Djibouti"},
    {"DK", "Denmark"},
    {"DM", "Dominica"},
    {"DO", "Dominican Republic"},
    {"DZ", "Algeria"},
    {"EC", "Ecuador"},
    {"EE", "Estonia"},
    {"EG", "Egypt"},
    {"EH", "Western Sahara"},
    {"ER", "Eritrea"},
    {"ES", "Spain"},
    {"ET", "Ethiopia"},
    {"FI", "Finland"},
    {"FJ", "Fiji"},
    {"FK", "Falkland Islands"},
    {"FO", "Faroe Islands"},
    {"FR", "France"},
    {"GA", "Gabon"},
    {"GD", "Grenada"},
    {"GE", "Georgia"},
    {"GF", "French Guiana"},
    {"GG", "Guernsey"},
    {"GH", "Ghana"},
    {"GI", "Gibraltar"},
    {"GL", "Greenland"},
    {"GM", "Gambia"},
    {"GN", "Guinea"},
    {"GP", "Guadeloupe"},
    {"GQ", "Equatorial Guinea"},
    {"GR", "Greece"},
    {"GS", "South Georgia and the South Sandwich Islands"},
    {"GT", "Guatemala"},
    {"GU", "Guam"},
    {"GW", "Guinea-Bissau"},
    {"GY", "Guyana"},
    {"HK", "Hong Kong"},
    {"HN", "Honduras"},
    {"HR", "Croatia"},
    {"HT", "Haiti"},
    {"HU", "Hungary"},
    {"ID", "Indonesia"},
    {"IE", "Ireland"},
    {"IL", "Israel"},
    {"IM", "Isle of Man"},
    {"IN", "India"},
    {"IO", "British Indian Ocean Territory"},
    {"IQ", "Iraq"},
    {"IS", "Iceland"},
    {"IT", "Italy"},
    {"JE", "Jersey"},
    {"JM", "Jamaica"},
    {"JO", "Jordan"},
    {"JP", "Japan"},
    {"KE", "Kenya"},
    {"KG", "Kyrgyzstan"},
    {"KH", "Cambodia"},
    {"KI", "Kiribati"},
    {"KM", "Comoros"},
    {"KN", "Saint Kitts and Nevis"},
    {"KR", "South Korea"},
    {"KW", "Kuwait"},
    {"KY", "Cayman Islands"},
    {"KZ", "Kazakhstan"},
    {"LA", "Laos"},
    {"LB", "Lebanon"},
    {"LC", "Saint Lucia"},
    {"LI", "Liechtenstein"},
    {"LK", "Sri Lanka"},
    {"LR", "Liberia"},
    {"LS", "Lesotho"},
    {"LT", "Lithuania"},
    {"LU", "Luxembourg"},
    {"LV", "Latvia"},
    {"LY", "Libya"},
    {"MA", "Morocco"},
    {"MC", "Monaco"},
    {"MD", "Moldova"},
    {"ME", "Montenegro"},
    {"MF", "Saint Martin"},
    {"MG", "Madagascar"},
    {"MK", "North Macedonia"},
    {"ML", "Mali"},
    {"MM", "Myanmar"},
    {"MN", "Mongolia"},
    {"MO", "Macau"},
    {"MQ", "Martinique"},
    {"MR", "Mauritania"},
    {"MS", "Montserrat"},
    {"MT", "Malta"},
    {"MU", "Mauritius"},
    {"MV", "Maldives"},
    {"MW", "Malawi"},
    {"MX", "Mexico"},
    {"MY", "Malaysia"},
    {"MZ", "Mozambique"},
    {"NA", "Namibia"},
    {"NC", "New Caledonia"},
    {"NE", "Niger"},
    {"NG", "Nigeria"},
    {"NI", "Nicaragua"},
    {"NL", "Netherlands"},
    {"NO", "Norway"},
    {"NP", "Nepal"},
    {"NR", "Nauru"},
    {"NU", "Niue"},
    {"NZ", "New Zealand"},
    {"OM", "Oman"},
    {"PA", "Panama"},
    {"PE", "Peru"},
    {"PF", "French Polynesia"},
    {"PG", "Papua New Guinea"},
    {"PH", "Philippines"},
    {"PK", "Pakistan"},
    {"PL", "Poland"},
    {"PM", "Saint Pierre and Miquelon"},
    {"PN", "Pitcairn Islands"},
    {"PR", "Puerto Rico"},
    {"PS", "Palestine"},
    {"PT", "Portugal"},
    {"PY", "Paraguay"},
    {"QA", "Qatar"},
    {"RE", "Réunion"},
    {"RO", "Romania"},
    {"RS", "Serbia"},
    {"RU", "Russia"},
    {"RW", "Rwanda"},
    {"SA", "Saudi Arabia"},
    {"SB", "Solomon Islands"},
    {"SC", "Seychelles"},
    {"SE", "Sweden"},
    {"SG", "Singapore"},
    {"SH", "Saint Helena"},
    {"SI", "Slovenia"},
    {"SJ", "Svalbard and Jan Mayen"},
    {"SK", "Slovakia"},
    {"SL", "Sierra Leone"},
    {"SM", "San Marino"},
    {"SN", "Senegal"},
    {"SO", "Somalia"},
    {"SR", "Suriname"},
    {"SS", "South Sudan"},
    {"ST", "São Tomé and Príncipe"},
    {"SV", "El Salvador"},
    {"SX", "Sint Maarten"},
    {"SZ", "Eswatini"},
    {"TA", "Tristan da Cunha"},
    {"TC", "Turks and Caicos Islands"},
    {"TD", "Chad"},
    {"TF", "French Southern Territories"},
    {"TG", "Togo"},
    {"TH", "Thailand"},
    {"TJ", "Tajikistan"},
    {"TK", "Tokelau"},
    {"TL", "Timor-Leste"},
    {"TM", "Turkmenistan"},
    {"TN", "Tunisia"},
    {"TO", "Tonga"},
    {"TR", "Turkey"},
    {"TT", "Trinidad and Tobago"},
    {"TV", "Tuvalu"},
    {"TW", "Taiwan"},
    {"TZ", "Tanzania"},
    {"UA", "Ukraine"},
    {"UG", "Uganda"},
    {"UY", "Uruguay"},
    {"UZ", "Uzbekistan"},
    {"VA", "Vatican City"},
    {"VC", "Saint Vincent and the Grenadines"},
    {"VE", "Venezuela"},
    {"VG", "British Virgin Islands"},
    {"VN", "Vietnam"},
    {"VU", "Vanuatu"},
    {"WF", "Wallis and Futuna"},
    {"WS", "Samoa"},
    {"XK", "Kosovo"},
    {"YE", "Yemen"},
    {"YT", "Mayotte"},
    {"ZA", "South Africa"},
    {"ZM", "Zambia"},
    {"ZW", "Zimbabwe"},
    {"ZZ", "Unknown or unspecified country"}
  ]

  @available_country_codes Enum.map(@available_countries, &elem(&1, 0))

  @available_countries_map Map.new(@available_countries)

  def available_countries, do: @available_countries
  def available_country_codes, do: @available_country_codes
  def country_name(code), do: @available_countries_map[code]
end
