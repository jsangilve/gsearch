defmodule GoogleSearch do
  @moduledoc """
  Provides a function to search terms on Google
  """
  alias HTTPoison

  @url_home "https://www.google.com/"
  @url_search "https://www.google.com/search"

  def fetch_page(url) do
    headers = [
      "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0"
    ]
    HTTPoison.request(:get, url, "", headers, [{:follow_redirect, true}])
  end

  def get_cookies() do
    {_, response} = fetch_page(@url_home)
    IO.inspect response.headers
  end

  def build_params(), do: %{}

  def search(term, site \\ nil) do
    url = "#{@url_search}?" <> URI.encode_query(%{q: term, as_sitesearch: site})
    IO.puts url
    {:ok, %HTTPoison.Response{body: body}} = fetch_page(url)
    Floki.find(body, "div.g h3.r > a")
    |> Enum.map(fn {_, [{"href", href} | _xs], _} -> IO.puts href end)
  end
end
